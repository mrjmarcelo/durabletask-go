-- ============================================================================
-- Enhanced Schema for Durable Task Backend (v2)
-- Includes performance optimizations and partitioning
-- Fixed: Storage parameters now applied to individual partitions instead of parent tables
-- Updated: Increased from 8 to 32 partitions for high concurrency (160 connections)
-- ============================================================================

-- ============================================================================
-- Instances Table (with performance optimizations)
-- ============================================================================
CREATE TABLE IF NOT EXISTS Instances (
    SequenceNumber BIGSERIAL,  -- Changed to BIGSERIAL for high scale
    
    InstanceID TEXT PRIMARY KEY NOT NULL,
    ExecutionID TEXT NOT NULL,
    Name TEXT NOT NULL, -- the type name of the orchestration or entity
    Version TEXT NULL, -- the version of the orchestration (optional)
    RuntimeStatus TEXT NOT NULL,
    CreatedTime TIMESTAMP NOT NULL DEFAULT NOW(),
    LastUpdatedTime TIMESTAMP NOT NULL DEFAULT NOW(),
    CompletedTime TIMESTAMP NULL,
    LockedBy TEXT NULL,
    LockExpiration TIMESTAMP NULL,
    Input TEXT NULL,
    Output TEXT NULL,
    CustomStatus TEXT NULL,
    FailureDetails BYTEA NULL,
    ParentInstanceID TEXT NULL
);

-- Fillfactor: Reduce page splits for HOT updates
ALTER TABLE Instances SET (fillfactor = 80);

-- Original indexes from base schema
CREATE INDEX IF NOT EXISTS IX_Instances_SequenceNumber ON Instances(SequenceNumber);
CREATE INDEX IF NOT EXISTS IX_Instances_CreatedTime ON Instances(CreatedTime);
CREATE INDEX IF NOT EXISTS IX_Instances_ParentInstanceID ON Instances(ParentInstanceID);

-- Composite index for suborchestration priority queries (ORDER BY ParentInstanceID, InstanceID, SequenceNumber)
CREATE INDEX IF NOT EXISTS IX_Instances_ParentInstanceID_InstanceID_SequenceNumber ON Instances(ParentInstanceID, InstanceID, SequenceNumber);

-- Performance optimization indexes
CREATE INDEX IF NOT EXISTS IX_Instances_LockExp_SeqNum_WHERE_LockExp_NULL ON Instances(LockExpiration, SequenceNumber)
WHERE LockExpiration IS NULL;

CREATE INDEX IF NOT EXISTS IX_Instances_RuntimeStatus_WHERE_RuntimeStatus_IN_PENDING_RUNNING ON Instances(RuntimeStatus)
WHERE RuntimeStatus IN ('PENDING', 'RUNNING');

-- Full index for ORDER BY InstanceID, SequenceNumber (supports all rows)
CREATE INDEX IF NOT EXISTS IX_Instances_InstanceID_SequenceNumber ON Instances(InstanceID, SequenceNumber);

-- Index for abandon/complete operations (WHERE InstanceID = $1 AND LockedBy = $2)
CREATE INDEX IF NOT EXISTS IX_Instances_InstanceID_LockedBy ON Instances(InstanceID, LockedBy);

-- Index for locking queries with ORDER BY (LockExpiration, InstanceID, SequenceNumber)
CREATE INDEX IF NOT EXISTS IX_Instances_LockExp_ID_SeqNum_WHERE_LockExp_NULL ON Instances(LockExpiration, InstanceID, SequenceNumber)
WHERE LockExpiration IS NULL;

-- Index for batch orchestration queries (ORDER BY SequenceNumber)
CREATE INDEX IF NOT EXISTS IX_Instances_SequenceNumber_WHERE_LockExpiration_IS_NULL ON Instances(SequenceNumber)
WHERE LockExpiration IS NULL;

-- Index for purge operations (WHERE RuntimeStatus IN ('COMPLETED', 'FAILED', 'TERMINATED'))
CREATE INDEX IF NOT EXISTS IX_Instances_RuntimeStatus_WHERE_IN_COMP_FAIL_TERM ON Instances(RuntimeStatus)
WHERE RuntimeStatus IN ('COMPLETED', 'FAILED', 'TERMINATED');

-- Index for reclaiming expired locks (WHERE LockExpiration < now, e.g. crashed/restarted workers)
-- Complements IX_Instances_LockExp_ID_SeqNum_WHERE_LockExp_NULL, which only covers the NULL branch
-- of the poll query's (LockExpiration IS NULL OR LockExpiration < $3) predicate.
CREATE INDEX IF NOT EXISTS IX_Instances_LockExp_NotNull_ID_SeqNum ON Instances(LockExpiration, InstanceID, SequenceNumber)
WHERE LockExpiration IS NOT NULL;

-- Supplementary, more selective poll index bounded to actionable instances (PENDING/RUNNING).
-- Stays small regardless of purge cadence, unlike IX_Instances_LockExp_ID_SeqNum_WHERE_LockExp_NULL
-- which grows with every unpurged completed/failed/terminated instance.
CREATE INDEX IF NOT EXISTS IX_Instances_LockExp_Null_Status_ID_SeqNum ON Instances(LockExpiration, InstanceID, SequenceNumber)
WHERE LockExpiration IS NULL AND RuntimeStatus IN ('PENDING', 'RUNNING');

-- Covering index for GetOrchestrationMetadata reads (SELECT ... WHERE InstanceID = $1).
-- Enables index-only scans for the common status-check case. Excludes Input/Output/FailureDetails
-- (large/variable size) to avoid bloating the index.
CREATE INDEX IF NOT EXISTS IX_Instances_InstanceID_Include_Metadata ON Instances(InstanceID)
INCLUDE (Name, RuntimeStatus, CreatedTime, LastUpdatedTime, CustomStatus);

-- ============================================================================
-- History Table (with performance optimizations)
-- ============================================================================
CREATE TABLE IF NOT EXISTS History (
    InstanceID TEXT NOT NULL,
    SequenceNumber BIGSERIAL NOT NULL,  -- Changed to BIGSERIAL for high scale
    EventPayload BYTEA NOT NULL,

    PRIMARY KEY (InstanceID, SequenceNumber)
);

-- Fillfactor: Reduce page splits for HOT updates (history is read-heavy)
ALTER TABLE History SET (fillfactor = 90);

-- ============================================================================
-- NewEvents Table (with partitioning and performance optimizations)
-- ============================================================================
CREATE TABLE IF NOT EXISTS NewEvents (
    SequenceNumber BIGSERIAL,  -- Changed to BIGSERIAL for high scale
    InstanceID TEXT NOT NULL,
    ExecutionID TEXT NULL,
    Timestamp TIMESTAMP NOT NULL DEFAULT NOW(),
    VisibleTime TIMESTAMP NULL, -- for scheduled or abandoned messages
    DequeueCount INTEGER NOT NULL DEFAULT 0,
    LockedBy TEXT NULL,
    EventPayload BYTEA NOT NULL,
    UNIQUE (InstanceID, SequenceNumber)
) PARTITION BY HASH (InstanceID);

-- Note: Fillfactor and autovacuum settings must be set on individual partitions, not the parent table

-- Create 64 partitions for parallelism with storage parameters
CREATE TABLE IF NOT EXISTS NewEvents_0000 PARTITION OF NewEvents FOR VALUES WITH (MODULUS 64, REMAINDER 0);
ALTER TABLE NewEvents_0000 SET (fillfactor = 70);
ALTER TABLE NewEvents_0000 SET (autovacuum_vacuum_scale_factor = 0.05, autovacuum_vacuum_threshold = 5000, autovacuum_analyze_scale_factor = 0.05, autovacuum_analyze_threshold = 2000);

CREATE TABLE IF NOT EXISTS NewEvents_0001 PARTITION OF NewEvents FOR VALUES WITH (MODULUS 64, REMAINDER 1);
ALTER TABLE NewEvents_0001 SET (fillfactor = 70);
ALTER TABLE NewEvents_0001 SET (autovacuum_vacuum_scale_factor = 0.05, autovacuum_vacuum_threshold = 5000, autovacuum_analyze_scale_factor = 0.05, autovacuum_analyze_threshold = 2000);

CREATE TABLE IF NOT EXISTS NewEvents_0002 PARTITION OF NewEvents FOR VALUES WITH (MODULUS 64, REMAINDER 2);
ALTER TABLE NewEvents_0002 SET (fillfactor = 70);
ALTER TABLE NewEvents_0002 SET (autovacuum_vacuum_scale_factor = 0.05, autovacuum_vacuum_threshold = 5000, autovacuum_analyze_scale_factor = 0.05, autovacuum_analyze_threshold = 2000);

CREATE TABLE IF NOT EXISTS NewEvents_0003 PARTITION OF NewEvents FOR VALUES WITH (MODULUS 64, REMAINDER 3);
ALTER TABLE NewEvents_0003 SET (fillfactor = 70);
ALTER TABLE NewEvents_0003 SET (autovacuum_vacuum_scale_factor = 0.05, autovacuum_vacuum_threshold = 5000, autovacuum_analyze_scale_factor = 0.05, autovacuum_analyze_threshold = 2000);

CREATE TABLE IF NOT EXISTS NewEvents_0004 PARTITION OF NewEvents FOR VALUES WITH (MODULUS 64, REMAINDER 4);
ALTER TABLE NewEvents_0004 SET (fillfactor = 70);
ALTER TABLE NewEvents_0004 SET (autovacuum_vacuum_scale_factor = 0.05, autovacuum_vacuum_threshold = 5000, autovacuum_analyze_scale_factor = 0.05, autovacuum_analyze_threshold = 2000);

CREATE TABLE IF NOT EXISTS NewEvents_0005 PARTITION OF NewEvents FOR VALUES WITH (MODULUS 64, REMAINDER 5);
ALTER TABLE NewEvents_0005 SET (fillfactor = 70);
ALTER TABLE NewEvents_0005 SET (autovacuum_vacuum_scale_factor = 0.05, autovacuum_vacuum_threshold = 5000, autovacuum_analyze_scale_factor = 0.05, autovacuum_analyze_threshold = 2000);

CREATE TABLE IF NOT EXISTS NewEvents_0006 PARTITION OF NewEvents FOR VALUES WITH (MODULUS 64, REMAINDER 6);
ALTER TABLE NewEvents_0006 SET (fillfactor = 70);
ALTER TABLE NewEvents_0006 SET (autovacuum_vacuum_scale_factor = 0.05, autovacuum_vacuum_threshold = 5000, autovacuum_analyze_scale_factor = 0.05, autovacuum_analyze_threshold = 2000);

CREATE TABLE IF NOT EXISTS NewEvents_0007 PARTITION OF NewEvents FOR VALUES WITH (MODULUS 64, REMAINDER 7);
ALTER TABLE NewEvents_0007 SET (fillfactor = 70);
ALTER TABLE NewEvents_0007 SET (autovacuum_vacuum_scale_factor = 0.05, autovacuum_vacuum_threshold = 5000, autovacuum_analyze_scale_factor = 0.05, autovacuum_analyze_threshold = 2000);

CREATE TABLE IF NOT EXISTS NewEvents_0008 PARTITION OF NewEvents FOR VALUES WITH (MODULUS 64, REMAINDER 8);
ALTER TABLE NewEvents_0008 SET (fillfactor = 70);
ALTER TABLE NewEvents_0008 SET (autovacuum_vacuum_scale_factor = 0.05, autovacuum_vacuum_threshold = 5000, autovacuum_analyze_scale_factor = 0.05, autovacuum_analyze_threshold = 2000);

CREATE TABLE IF NOT EXISTS NewEvents_0009 PARTITION OF NewEvents FOR VALUES WITH (MODULUS 64, REMAINDER 9);
ALTER TABLE NewEvents_0009 SET (fillfactor = 70);
ALTER TABLE NewEvents_0009 SET (autovacuum_vacuum_scale_factor = 0.05, autovacuum_vacuum_threshold = 5000, autovacuum_analyze_scale_factor = 0.05, autovacuum_analyze_threshold = 2000);

CREATE TABLE IF NOT EXISTS NewEvents_0010 PARTITION OF NewEvents FOR VALUES WITH (MODULUS 64, REMAINDER 10);
ALTER TABLE NewEvents_0010 SET (fillfactor = 70);
ALTER TABLE NewEvents_0010 SET (autovacuum_vacuum_scale_factor = 0.05, autovacuum_vacuum_threshold = 5000, autovacuum_analyze_scale_factor = 0.05, autovacuum_analyze_threshold = 2000);

CREATE TABLE IF NOT EXISTS NewEvents_0011 PARTITION OF NewEvents FOR VALUES WITH (MODULUS 64, REMAINDER 11);
ALTER TABLE NewEvents_0011 SET (fillfactor = 70);
ALTER TABLE NewEvents_0011 SET (autovacuum_vacuum_scale_factor = 0.05, autovacuum_vacuum_threshold = 5000, autovacuum_analyze_scale_factor = 0.05, autovacuum_analyze_threshold = 2000);

CREATE TABLE IF NOT EXISTS NewEvents_0012 PARTITION OF NewEvents FOR VALUES WITH (MODULUS 64, REMAINDER 12);
ALTER TABLE NewEvents_0012 SET (fillfactor = 70);
ALTER TABLE NewEvents_0012 SET (autovacuum_vacuum_scale_factor = 0.05, autovacuum_vacuum_threshold = 5000, autovacuum_analyze_scale_factor = 0.05, autovacuum_analyze_threshold = 2000);

CREATE TABLE IF NOT EXISTS NewEvents_0013 PARTITION OF NewEvents FOR VALUES WITH (MODULUS 64, REMAINDER 13);
ALTER TABLE NewEvents_0013 SET (fillfactor = 70);
ALTER TABLE NewEvents_0013 SET (autovacuum_vacuum_scale_factor = 0.05, autovacuum_vacuum_threshold = 5000, autovacuum_analyze_scale_factor = 0.05, autovacuum_analyze_threshold = 2000);

CREATE TABLE IF NOT EXISTS NewEvents_0014 PARTITION OF NewEvents FOR VALUES WITH (MODULUS 64, REMAINDER 14);
ALTER TABLE NewEvents_0014 SET (fillfactor = 70);
ALTER TABLE NewEvents_0014 SET (autovacuum_vacuum_scale_factor = 0.05, autovacuum_vacuum_threshold = 5000, autovacuum_analyze_scale_factor = 0.05, autovacuum_analyze_threshold = 2000);

CREATE TABLE IF NOT EXISTS NewEvents_0015 PARTITION OF NewEvents FOR VALUES WITH (MODULUS 64, REMAINDER 15);
ALTER TABLE NewEvents_0015 SET (fillfactor = 70);
ALTER TABLE NewEvents_0015 SET (autovacuum_vacuum_scale_factor = 0.05, autovacuum_vacuum_threshold = 5000, autovacuum_analyze_scale_factor = 0.05, autovacuum_analyze_threshold = 2000);

CREATE TABLE IF NOT EXISTS NewEvents_0016 PARTITION OF NewEvents FOR VALUES WITH (MODULUS 64, REMAINDER 16);
ALTER TABLE NewEvents_0016 SET (fillfactor = 70);
ALTER TABLE NewEvents_0016 SET (autovacuum_vacuum_scale_factor = 0.05, autovacuum_vacuum_threshold = 5000, autovacuum_analyze_scale_factor = 0.05, autovacuum_analyze_threshold = 2000);

CREATE TABLE IF NOT EXISTS NewEvents_0017 PARTITION OF NewEvents FOR VALUES WITH (MODULUS 64, REMAINDER 17);
ALTER TABLE NewEvents_0017 SET (fillfactor = 70);
ALTER TABLE NewEvents_0017 SET (autovacuum_vacuum_scale_factor = 0.05, autovacuum_vacuum_threshold = 5000, autovacuum_analyze_scale_factor = 0.05, autovacuum_analyze_threshold = 2000);

CREATE TABLE IF NOT EXISTS NewEvents_0018 PARTITION OF NewEvents FOR VALUES WITH (MODULUS 64, REMAINDER 18);
ALTER TABLE NewEvents_0018 SET (fillfactor = 70);
ALTER TABLE NewEvents_0018 SET (autovacuum_vacuum_scale_factor = 0.05, autovacuum_vacuum_threshold = 5000, autovacuum_analyze_scale_factor = 0.05, autovacuum_analyze_threshold = 2000);

CREATE TABLE IF NOT EXISTS NewEvents_0019 PARTITION OF NewEvents FOR VALUES WITH (MODULUS 64, REMAINDER 19);
ALTER TABLE NewEvents_0019 SET (fillfactor = 70);
ALTER TABLE NewEvents_0019 SET (autovacuum_vacuum_scale_factor = 0.05, autovacuum_vacuum_threshold = 5000, autovacuum_analyze_scale_factor = 0.05, autovacuum_analyze_threshold = 2000);

CREATE TABLE IF NOT EXISTS NewEvents_0020 PARTITION OF NewEvents FOR VALUES WITH (MODULUS 64, REMAINDER 20);
ALTER TABLE NewEvents_0020 SET (fillfactor = 70);
ALTER TABLE NewEvents_0020 SET (autovacuum_vacuum_scale_factor = 0.05, autovacuum_vacuum_threshold = 5000, autovacuum_analyze_scale_factor = 0.05, autovacuum_analyze_threshold = 2000);

CREATE TABLE IF NOT EXISTS NewEvents_0021 PARTITION OF NewEvents FOR VALUES WITH (MODULUS 64, REMAINDER 21);
ALTER TABLE NewEvents_0021 SET (fillfactor = 70);
ALTER TABLE NewEvents_0021 SET (autovacuum_vacuum_scale_factor = 0.05, autovacuum_vacuum_threshold = 5000, autovacuum_analyze_scale_factor = 0.05, autovacuum_analyze_threshold = 2000);

CREATE TABLE IF NOT EXISTS NewEvents_0022 PARTITION OF NewEvents FOR VALUES WITH (MODULUS 64, REMAINDER 22);
ALTER TABLE NewEvents_0022 SET (fillfactor = 70);
ALTER TABLE NewEvents_0022 SET (autovacuum_vacuum_scale_factor = 0.05, autovacuum_vacuum_threshold = 5000, autovacuum_analyze_scale_factor = 0.05, autovacuum_analyze_threshold = 2000);

CREATE TABLE IF NOT EXISTS NewEvents_0023 PARTITION OF NewEvents FOR VALUES WITH (MODULUS 64, REMAINDER 23);
ALTER TABLE NewEvents_0023 SET (fillfactor = 70);
ALTER TABLE NewEvents_0023 SET (autovacuum_vacuum_scale_factor = 0.05, autovacuum_vacuum_threshold = 5000, autovacuum_analyze_scale_factor = 0.05, autovacuum_analyze_threshold = 2000);

CREATE TABLE IF NOT EXISTS NewEvents_0024 PARTITION OF NewEvents FOR VALUES WITH (MODULUS 64, REMAINDER 24);
ALTER TABLE NewEvents_0024 SET (fillfactor = 70);
ALTER TABLE NewEvents_0024 SET (autovacuum_vacuum_scale_factor = 0.05, autovacuum_vacuum_threshold = 5000, autovacuum_analyze_scale_factor = 0.05, autovacuum_analyze_threshold = 2000);

CREATE TABLE IF NOT EXISTS NewEvents_0025 PARTITION OF NewEvents FOR VALUES WITH (MODULUS 64, REMAINDER 25);
ALTER TABLE NewEvents_0025 SET (fillfactor = 70);
ALTER TABLE NewEvents_0025 SET (autovacuum_vacuum_scale_factor = 0.05, autovacuum_vacuum_threshold = 5000, autovacuum_analyze_scale_factor = 0.05, autovacuum_analyze_threshold = 2000);

CREATE TABLE IF NOT EXISTS NewEvents_0026 PARTITION OF NewEvents FOR VALUES WITH (MODULUS 64, REMAINDER 26);
ALTER TABLE NewEvents_0026 SET (fillfactor = 70);
ALTER TABLE NewEvents_0026 SET (autovacuum_vacuum_scale_factor = 0.05, autovacuum_vacuum_threshold = 5000, autovacuum_analyze_scale_factor = 0.05, autovacuum_analyze_threshold = 2000);

CREATE TABLE IF NOT EXISTS NewEvents_0027 PARTITION OF NewEvents FOR VALUES WITH (MODULUS 64, REMAINDER 27);
ALTER TABLE NewEvents_0027 SET (fillfactor = 70);
ALTER TABLE NewEvents_0027 SET (autovacuum_vacuum_scale_factor = 0.05, autovacuum_vacuum_threshold = 5000, autovacuum_analyze_scale_factor = 0.05, autovacuum_analyze_threshold = 2000);

CREATE TABLE IF NOT EXISTS NewEvents_0028 PARTITION OF NewEvents FOR VALUES WITH (MODULUS 64, REMAINDER 28);
ALTER TABLE NewEvents_0028 SET (fillfactor = 70);
ALTER TABLE NewEvents_0028 SET (autovacuum_vacuum_scale_factor = 0.05, autovacuum_vacuum_threshold = 5000, autovacuum_analyze_scale_factor = 0.05, autovacuum_analyze_threshold = 2000);

CREATE TABLE IF NOT EXISTS NewEvents_0029 PARTITION OF NewEvents FOR VALUES WITH (MODULUS 64, REMAINDER 29);
ALTER TABLE NewEvents_0029 SET (fillfactor = 70);
ALTER TABLE NewEvents_0029 SET (autovacuum_vacuum_scale_factor = 0.05, autovacuum_vacuum_threshold = 5000, autovacuum_analyze_scale_factor = 0.05, autovacuum_analyze_threshold = 2000);

CREATE TABLE IF NOT EXISTS NewEvents_0030 PARTITION OF NewEvents FOR VALUES WITH (MODULUS 64, REMAINDER 30);
ALTER TABLE NewEvents_0030 SET (fillfactor = 70);
ALTER TABLE NewEvents_0030 SET (autovacuum_vacuum_scale_factor = 0.05, autovacuum_vacuum_threshold = 5000, autovacuum_analyze_scale_factor = 0.05, autovacuum_analyze_threshold = 2000);

CREATE TABLE IF NOT EXISTS NewEvents_0031 PARTITION OF NewEvents FOR VALUES WITH (MODULUS 64, REMAINDER 31);
ALTER TABLE NewEvents_0031 SET (fillfactor = 70);
ALTER TABLE NewEvents_0031 SET (autovacuum_vacuum_scale_factor = 0.05, autovacuum_vacuum_threshold = 5000, autovacuum_analyze_scale_factor = 0.05, autovacuum_analyze_threshold = 2000);

CREATE TABLE IF NOT EXISTS NewEvents_0032 PARTITION OF NewEvents FOR VALUES WITH (MODULUS 64, REMAINDER 32);
ALTER TABLE NewEvents_0032 SET (fillfactor = 70);
ALTER TABLE NewEvents_0032 SET (autovacuum_vacuum_scale_factor = 0.05, autovacuum_vacuum_threshold = 5000, autovacuum_analyze_scale_factor = 0.05, autovacuum_analyze_threshold = 2000);

CREATE TABLE IF NOT EXISTS NewEvents_0033 PARTITION OF NewEvents FOR VALUES WITH (MODULUS 64, REMAINDER 33);
ALTER TABLE NewEvents_0033 SET (fillfactor = 70);
ALTER TABLE NewEvents_0033 SET (autovacuum_vacuum_scale_factor = 0.05, autovacuum_vacuum_threshold = 5000, autovacuum_analyze_scale_factor = 0.05, autovacuum_analyze_threshold = 2000);

CREATE TABLE IF NOT EXISTS NewEvents_0034 PARTITION OF NewEvents FOR VALUES WITH (MODULUS 64, REMAINDER 34);
ALTER TABLE NewEvents_0034 SET (fillfactor = 70);
ALTER TABLE NewEvents_0034 SET (autovacuum_vacuum_scale_factor = 0.05, autovacuum_vacuum_threshold = 5000, autovacuum_analyze_scale_factor = 0.05, autovacuum_analyze_threshold = 2000);

CREATE TABLE IF NOT EXISTS NewEvents_0035 PARTITION OF NewEvents FOR VALUES WITH (MODULUS 64, REMAINDER 35);
ALTER TABLE NewEvents_0035 SET (fillfactor = 70);
ALTER TABLE NewEvents_0035 SET (autovacuum_vacuum_scale_factor = 0.05, autovacuum_vacuum_threshold = 5000, autovacuum_analyze_scale_factor = 0.05, autovacuum_analyze_threshold = 2000);

CREATE TABLE IF NOT EXISTS NewEvents_0036 PARTITION OF NewEvents FOR VALUES WITH (MODULUS 64, REMAINDER 36);
ALTER TABLE NewEvents_0036 SET (fillfactor = 70);
ALTER TABLE NewEvents_0036 SET (autovacuum_vacuum_scale_factor = 0.05, autovacuum_vacuum_threshold = 5000, autovacuum_analyze_scale_factor = 0.05, autovacuum_analyze_threshold = 2000);

CREATE TABLE IF NOT EXISTS NewEvents_0037 PARTITION OF NewEvents FOR VALUES WITH (MODULUS 64, REMAINDER 37);
ALTER TABLE NewEvents_0037 SET (fillfactor = 70);
ALTER TABLE NewEvents_0037 SET (autovacuum_vacuum_scale_factor = 0.05, autovacuum_vacuum_threshold = 5000, autovacuum_analyze_scale_factor = 0.05, autovacuum_analyze_threshold = 2000);

CREATE TABLE IF NOT EXISTS NewEvents_0038 PARTITION OF NewEvents FOR VALUES WITH (MODULUS 64, REMAINDER 38);
ALTER TABLE NewEvents_0038 SET (fillfactor = 70);
ALTER TABLE NewEvents_0038 SET (autovacuum_vacuum_scale_factor = 0.05, autovacuum_vacuum_threshold = 5000, autovacuum_analyze_scale_factor = 0.05, autovacuum_analyze_threshold = 2000);

CREATE TABLE IF NOT EXISTS NewEvents_0039 PARTITION OF NewEvents FOR VALUES WITH (MODULUS 64, REMAINDER 39);
ALTER TABLE NewEvents_0039 SET (fillfactor = 70);
ALTER TABLE NewEvents_0039 SET (autovacuum_vacuum_scale_factor = 0.05, autovacuum_vacuum_threshold = 5000, autovacuum_analyze_scale_factor = 0.05, autovacuum_analyze_threshold = 2000);

CREATE TABLE IF NOT EXISTS NewEvents_0040 PARTITION OF NewEvents FOR VALUES WITH (MODULUS 64, REMAINDER 40);
ALTER TABLE NewEvents_0040 SET (fillfactor = 70);
ALTER TABLE NewEvents_0040 SET (autovacuum_vacuum_scale_factor = 0.05, autovacuum_vacuum_threshold = 5000, autovacuum_analyze_scale_factor = 0.05, autovacuum_analyze_threshold = 2000);

CREATE TABLE IF NOT EXISTS NewEvents_0041 PARTITION OF NewEvents FOR VALUES WITH (MODULUS 64, REMAINDER 41);
ALTER TABLE NewEvents_0041 SET (fillfactor = 70);
ALTER TABLE NewEvents_0041 SET (autovacuum_vacuum_scale_factor = 0.05, autovacuum_vacuum_threshold = 5000, autovacuum_analyze_scale_factor = 0.05, autovacuum_analyze_threshold = 2000);

CREATE TABLE IF NOT EXISTS NewEvents_0042 PARTITION OF NewEvents FOR VALUES WITH (MODULUS 64, REMAINDER 42);
ALTER TABLE NewEvents_0042 SET (fillfactor = 70);
ALTER TABLE NewEvents_0042 SET (autovacuum_vacuum_scale_factor = 0.05, autovacuum_vacuum_threshold = 5000, autovacuum_analyze_scale_factor = 0.05, autovacuum_analyze_threshold = 2000);

CREATE TABLE IF NOT EXISTS NewEvents_0043 PARTITION OF NewEvents FOR VALUES WITH (MODULUS 64, REMAINDER 43);
ALTER TABLE NewEvents_0043 SET (fillfactor = 70);
ALTER TABLE NewEvents_0043 SET (autovacuum_vacuum_scale_factor = 0.05, autovacuum_vacuum_threshold = 5000, autovacuum_analyze_scale_factor = 0.05, autovacuum_analyze_threshold = 2000);

CREATE TABLE IF NOT EXISTS NewEvents_0044 PARTITION OF NewEvents FOR VALUES WITH (MODULUS 64, REMAINDER 44);
ALTER TABLE NewEvents_0044 SET (fillfactor = 70);
ALTER TABLE NewEvents_0044 SET (autovacuum_vacuum_scale_factor = 0.05, autovacuum_vacuum_threshold = 5000, autovacuum_analyze_scale_factor = 0.05, autovacuum_analyze_threshold = 2000);

CREATE TABLE IF NOT EXISTS NewEvents_0045 PARTITION OF NewEvents FOR VALUES WITH (MODULUS 64, REMAINDER 45);
ALTER TABLE NewEvents_0045 SET (fillfactor = 70);
ALTER TABLE NewEvents_0045 SET (autovacuum_vacuum_scale_factor = 0.05, autovacuum_vacuum_threshold = 5000, autovacuum_analyze_scale_factor = 0.05, autovacuum_analyze_threshold = 2000);

CREATE TABLE IF NOT EXISTS NewEvents_0046 PARTITION OF NewEvents FOR VALUES WITH (MODULUS 64, REMAINDER 46);
ALTER TABLE NewEvents_0046 SET (fillfactor = 70);
ALTER TABLE NewEvents_0046 SET (autovacuum_vacuum_scale_factor = 0.05, autovacuum_vacuum_threshold = 5000, autovacuum_analyze_scale_factor = 0.05, autovacuum_analyze_threshold = 2000);

CREATE TABLE IF NOT EXISTS NewEvents_0047 PARTITION OF NewEvents FOR VALUES WITH (MODULUS 64, REMAINDER 47);
ALTER TABLE NewEvents_0047 SET (fillfactor = 70);
ALTER TABLE NewEvents_0047 SET (autovacuum_vacuum_scale_factor = 0.05, autovacuum_vacuum_threshold = 5000, autovacuum_analyze_scale_factor = 0.05, autovacuum_analyze_threshold = 2000);

CREATE TABLE IF NOT EXISTS NewEvents_0048 PARTITION OF NewEvents FOR VALUES WITH (MODULUS 64, REMAINDER 48);
ALTER TABLE NewEvents_0048 SET (fillfactor = 70);
ALTER TABLE NewEvents_0048 SET (autovacuum_vacuum_scale_factor = 0.05, autovacuum_vacuum_threshold = 5000, autovacuum_analyze_scale_factor = 0.05, autovacuum_analyze_threshold = 2000);

CREATE TABLE IF NOT EXISTS NewEvents_0049 PARTITION OF NewEvents FOR VALUES WITH (MODULUS 64, REMAINDER 49);
ALTER TABLE NewEvents_0049 SET (fillfactor = 70);
ALTER TABLE NewEvents_0049 SET (autovacuum_vacuum_scale_factor = 0.05, autovacuum_vacuum_threshold = 5000, autovacuum_analyze_scale_factor = 0.05, autovacuum_analyze_threshold = 2000);

CREATE TABLE IF NOT EXISTS NewEvents_0050 PARTITION OF NewEvents FOR VALUES WITH (MODULUS 64, REMAINDER 50);
ALTER TABLE NewEvents_0050 SET (fillfactor = 70);
ALTER TABLE NewEvents_0050 SET (autovacuum_vacuum_scale_factor = 0.05, autovacuum_vacuum_threshold = 5000, autovacuum_analyze_scale_factor = 0.05, autovacuum_analyze_threshold = 2000);

CREATE TABLE IF NOT EXISTS NewEvents_0051 PARTITION OF NewEvents FOR VALUES WITH (MODULUS 64, REMAINDER 51);
ALTER TABLE NewEvents_0051 SET (fillfactor = 70);
ALTER TABLE NewEvents_0051 SET (autovacuum_vacuum_scale_factor = 0.05, autovacuum_vacuum_threshold = 5000, autovacuum_analyze_scale_factor = 0.05, autovacuum_analyze_threshold = 2000);

CREATE TABLE IF NOT EXISTS NewEvents_0052 PARTITION OF NewEvents FOR VALUES WITH (MODULUS 64, REMAINDER 52);
ALTER TABLE NewEvents_0052 SET (fillfactor = 70);
ALTER TABLE NewEvents_0052 SET (autovacuum_vacuum_scale_factor = 0.05, autovacuum_vacuum_threshold = 5000, autovacuum_analyze_scale_factor = 0.05, autovacuum_analyze_threshold = 2000);

CREATE TABLE IF NOT EXISTS NewEvents_0053 PARTITION OF NewEvents FOR VALUES WITH (MODULUS 64, REMAINDER 53);
ALTER TABLE NewEvents_0053 SET (fillfactor = 70);
ALTER TABLE NewEvents_0053 SET (autovacuum_vacuum_scale_factor = 0.05, autovacuum_vacuum_threshold = 5000, autovacuum_analyze_scale_factor = 0.05, autovacuum_analyze_threshold = 2000);

CREATE TABLE IF NOT EXISTS NewEvents_0054 PARTITION OF NewEvents FOR VALUES WITH (MODULUS 64, REMAINDER 54);
ALTER TABLE NewEvents_0054 SET (fillfactor = 70);
ALTER TABLE NewEvents_0054 SET (autovacuum_vacuum_scale_factor = 0.05, autovacuum_vacuum_threshold = 5000, autovacuum_analyze_scale_factor = 0.05, autovacuum_analyze_threshold = 2000);

CREATE TABLE IF NOT EXISTS NewEvents_0055 PARTITION OF NewEvents FOR VALUES WITH (MODULUS 64, REMAINDER 55);
ALTER TABLE NewEvents_0055 SET (fillfactor = 70);
ALTER TABLE NewEvents_0055 SET (autovacuum_vacuum_scale_factor = 0.05, autovacuum_vacuum_threshold = 5000, autovacuum_analyze_scale_factor = 0.05, autovacuum_analyze_threshold = 2000);

CREATE TABLE IF NOT EXISTS NewEvents_0056 PARTITION OF NewEvents FOR VALUES WITH (MODULUS 64, REMAINDER 56);
ALTER TABLE NewEvents_0056 SET (fillfactor = 70);
ALTER TABLE NewEvents_0056 SET (autovacuum_vacuum_scale_factor = 0.05, autovacuum_vacuum_threshold = 5000, autovacuum_analyze_scale_factor = 0.05, autovacuum_analyze_threshold = 2000);

CREATE TABLE IF NOT EXISTS NewEvents_0057 PARTITION OF NewEvents FOR VALUES WITH (MODULUS 64, REMAINDER 57);
ALTER TABLE NewEvents_0057 SET (fillfactor = 70);
ALTER TABLE NewEvents_0057 SET (autovacuum_vacuum_scale_factor = 0.05, autovacuum_vacuum_threshold = 5000, autovacuum_analyze_scale_factor = 0.05, autovacuum_analyze_threshold = 2000);

CREATE TABLE IF NOT EXISTS NewEvents_0058 PARTITION OF NewEvents FOR VALUES WITH (MODULUS 64, REMAINDER 58);
ALTER TABLE NewEvents_0058 SET (fillfactor = 70);
ALTER TABLE NewEvents_0058 SET (autovacuum_vacuum_scale_factor = 0.05, autovacuum_vacuum_threshold = 5000, autovacuum_analyze_scale_factor = 0.05, autovacuum_analyze_threshold = 2000);

CREATE TABLE IF NOT EXISTS NewEvents_0059 PARTITION OF NewEvents FOR VALUES WITH (MODULUS 64, REMAINDER 59);
ALTER TABLE NewEvents_0059 SET (fillfactor = 70);
ALTER TABLE NewEvents_0059 SET (autovacuum_vacuum_scale_factor = 0.05, autovacuum_vacuum_threshold = 5000, autovacuum_analyze_scale_factor = 0.05, autovacuum_analyze_threshold = 2000);

CREATE TABLE IF NOT EXISTS NewEvents_0060 PARTITION OF NewEvents FOR VALUES WITH (MODULUS 64, REMAINDER 60);
ALTER TABLE NewEvents_0060 SET (fillfactor = 70);
ALTER TABLE NewEvents_0060 SET (autovacuum_vacuum_scale_factor = 0.05, autovacuum_vacuum_threshold = 5000, autovacuum_analyze_scale_factor = 0.05, autovacuum_analyze_threshold = 2000);

CREATE TABLE IF NOT EXISTS NewEvents_0061 PARTITION OF NewEvents FOR VALUES WITH (MODULUS 64, REMAINDER 61);
ALTER TABLE NewEvents_0061 SET (fillfactor = 70);
ALTER TABLE NewEvents_0061 SET (autovacuum_vacuum_scale_factor = 0.05, autovacuum_vacuum_threshold = 5000, autovacuum_analyze_scale_factor = 0.05, autovacuum_analyze_threshold = 2000);

CREATE TABLE IF NOT EXISTS NewEvents_0062 PARTITION OF NewEvents FOR VALUES WITH (MODULUS 64, REMAINDER 62);
ALTER TABLE NewEvents_0062 SET (fillfactor = 70);
ALTER TABLE NewEvents_0062 SET (autovacuum_vacuum_scale_factor = 0.05, autovacuum_vacuum_threshold = 5000, autovacuum_analyze_scale_factor = 0.05, autovacuum_analyze_threshold = 2000);

CREATE TABLE IF NOT EXISTS NewEvents_0063 PARTITION OF NewEvents FOR VALUES WITH (MODULUS 64, REMAINDER 63);
ALTER TABLE NewEvents_0063 SET (fillfactor = 70);
ALTER TABLE NewEvents_0063 SET (autovacuum_vacuum_scale_factor = 0.05, autovacuum_vacuum_threshold = 5000, autovacuum_analyze_scale_factor = 0.05, autovacuum_analyze_threshold = 2000);

-- Performance optimization indexes for each partition
CREATE INDEX IF NOT EXISTS IX_NewEvents_0000_ID_SeqNum_WHERE_LockedBy_NULL ON NewEvents_0000(InstanceID, SequenceNumber) WHERE LockedBy IS NULL;
CREATE INDEX IF NOT EXISTS IX_NewEvents_0001_ID_SeqNum_WHERE_LockedBy_NULL ON NewEvents_0001(InstanceID, SequenceNumber) WHERE LockedBy IS NULL;
CREATE INDEX IF NOT EXISTS IX_NewEvents_0002_ID_SeqNum_WHERE_LockedBy_NULL ON NewEvents_0002(InstanceID, SequenceNumber) WHERE LockedBy IS NULL;
CREATE INDEX IF NOT EXISTS IX_NewEvents_0003_ID_SeqNum_WHERE_LockedBy_NULL ON NewEvents_0003(InstanceID, SequenceNumber) WHERE LockedBy IS NULL;
CREATE INDEX IF NOT EXISTS IX_NewEvents_0004_ID_SeqNum_WHERE_LockedBy_NULL ON NewEvents_0004(InstanceID, SequenceNumber) WHERE LockedBy IS NULL;
CREATE INDEX IF NOT EXISTS IX_NewEvents_0005_ID_SeqNum_WHERE_LockedBy_NULL ON NewEvents_0005(InstanceID, SequenceNumber) WHERE LockedBy IS NULL;
CREATE INDEX IF NOT EXISTS IX_NewEvents_0006_ID_SeqNum_WHERE_LockedBy_NULL ON NewEvents_0006(InstanceID, SequenceNumber) WHERE LockedBy IS NULL;
CREATE INDEX IF NOT EXISTS IX_NewEvents_0007_ID_SeqNum_WHERE_LockedBy_NULL ON NewEvents_0007(InstanceID, SequenceNumber) WHERE LockedBy IS NULL;
CREATE INDEX IF NOT EXISTS IX_NewEvents_0008_ID_SeqNum_WHERE_LockedBy_NULL ON NewEvents_0008(InstanceID, SequenceNumber) WHERE LockedBy IS NULL;
CREATE INDEX IF NOT EXISTS IX_NewEvents_0009_ID_SeqNum_WHERE_LockedBy_NULL ON NewEvents_0009(InstanceID, SequenceNumber) WHERE LockedBy IS NULL;
CREATE INDEX IF NOT EXISTS IX_NewEvents_0010_ID_SeqNum_WHERE_LockedBy_NULL ON NewEvents_0010(InstanceID, SequenceNumber) WHERE LockedBy IS NULL;
CREATE INDEX IF NOT EXISTS IX_NewEvents_0011_ID_SeqNum_WHERE_LockedBy_NULL ON NewEvents_0011(InstanceID, SequenceNumber) WHERE LockedBy IS NULL;
CREATE INDEX IF NOT EXISTS IX_NewEvents_0012_ID_SeqNum_WHERE_LockedBy_NULL ON NewEvents_0012(InstanceID, SequenceNumber) WHERE LockedBy IS NULL;
CREATE INDEX IF NOT EXISTS IX_NewEvents_0013_ID_SeqNum_WHERE_LockedBy_NULL ON NewEvents_0013(InstanceID, SequenceNumber) WHERE LockedBy IS NULL;
CREATE INDEX IF NOT EXISTS IX_NewEvents_0014_ID_SeqNum_WHERE_LockedBy_NULL ON NewEvents_0014(InstanceID, SequenceNumber) WHERE LockedBy IS NULL;
CREATE INDEX IF NOT EXISTS IX_NewEvents_0015_ID_SeqNum_WHERE_LockedBy_NULL ON NewEvents_0015(InstanceID, SequenceNumber) WHERE LockedBy IS NULL;
CREATE INDEX IF NOT EXISTS IX_NewEvents_0016_ID_SeqNum_WHERE_LockedBy_NULL ON NewEvents_0016(InstanceID, SequenceNumber) WHERE LockedBy IS NULL;
CREATE INDEX IF NOT EXISTS IX_NewEvents_0017_ID_SeqNum_WHERE_LockedBy_NULL ON NewEvents_0017(InstanceID, SequenceNumber) WHERE LockedBy IS NULL;
CREATE INDEX IF NOT EXISTS IX_NewEvents_0018_ID_SeqNum_WHERE_LockedBy_NULL ON NewEvents_0018(InstanceID, SequenceNumber) WHERE LockedBy IS NULL;
CREATE INDEX IF NOT EXISTS IX_NewEvents_0019_ID_SeqNum_WHERE_LockedBy_NULL ON NewEvents_0019(InstanceID, SequenceNumber) WHERE LockedBy IS NULL;
CREATE INDEX IF NOT EXISTS IX_NewEvents_0020_ID_SeqNum_WHERE_LockedBy_NULL ON NewEvents_0020(InstanceID, SequenceNumber) WHERE LockedBy IS NULL;
CREATE INDEX IF NOT EXISTS IX_NewEvents_0021_ID_SeqNum_WHERE_LockedBy_NULL ON NewEvents_0021(InstanceID, SequenceNumber) WHERE LockedBy IS NULL;
CREATE INDEX IF NOT EXISTS IX_NewEvents_0022_ID_SeqNum_WHERE_LockedBy_NULL ON NewEvents_0022(InstanceID, SequenceNumber) WHERE LockedBy IS NULL;
CREATE INDEX IF NOT EXISTS IX_NewEvents_0023_ID_SeqNum_WHERE_LockedBy_NULL ON NewEvents_0023(InstanceID, SequenceNumber) WHERE LockedBy IS NULL;
CREATE INDEX IF NOT EXISTS IX_NewEvents_0024_ID_SeqNum_WHERE_LockedBy_NULL ON NewEvents_0024(InstanceID, SequenceNumber) WHERE LockedBy IS NULL;
CREATE INDEX IF NOT EXISTS IX_NewEvents_0025_ID_SeqNum_WHERE_LockedBy_NULL ON NewEvents_0025(InstanceID, SequenceNumber) WHERE LockedBy IS NULL;
CREATE INDEX IF NOT EXISTS IX_NewEvents_0026_ID_SeqNum_WHERE_LockedBy_NULL ON NewEvents_0026(InstanceID, SequenceNumber) WHERE LockedBy IS NULL;
CREATE INDEX IF NOT EXISTS IX_NewEvents_0027_ID_SeqNum_WHERE_LockedBy_NULL ON NewEvents_0027(InstanceID, SequenceNumber) WHERE LockedBy IS NULL;
CREATE INDEX IF NOT EXISTS IX_NewEvents_0028_ID_SeqNum_WHERE_LockedBy_NULL ON NewEvents_0028(InstanceID, SequenceNumber) WHERE LockedBy IS NULL;
CREATE INDEX IF NOT EXISTS IX_NewEvents_0029_ID_SeqNum_WHERE_LockedBy_NULL ON NewEvents_0029(InstanceID, SequenceNumber) WHERE LockedBy IS NULL;
CREATE INDEX IF NOT EXISTS IX_NewEvents_0030_ID_SeqNum_WHERE_LockedBy_NULL ON NewEvents_0030(InstanceID, SequenceNumber) WHERE LockedBy IS NULL;
CREATE INDEX IF NOT EXISTS IX_NewEvents_0031_ID_SeqNum_WHERE_LockedBy_NULL ON NewEvents_0031(InstanceID, SequenceNumber) WHERE LockedBy IS NULL;
CREATE INDEX IF NOT EXISTS IX_NewEvents_0032_ID_SeqNum_WHERE_LockedBy_NULL ON NewEvents_0032(InstanceID, SequenceNumber) WHERE LockedBy IS NULL;
CREATE INDEX IF NOT EXISTS IX_NewEvents_0033_ID_SeqNum_WHERE_LockedBy_NULL ON NewEvents_0033(InstanceID, SequenceNumber) WHERE LockedBy IS NULL;
CREATE INDEX IF NOT EXISTS IX_NewEvents_0034_ID_SeqNum_WHERE_LockedBy_NULL ON NewEvents_0034(InstanceID, SequenceNumber) WHERE LockedBy IS NULL;
CREATE INDEX IF NOT EXISTS IX_NewEvents_0035_ID_SeqNum_WHERE_LockedBy_NULL ON NewEvents_0035(InstanceID, SequenceNumber) WHERE LockedBy IS NULL;
CREATE INDEX IF NOT EXISTS IX_NewEvents_0036_ID_SeqNum_WHERE_LockedBy_NULL ON NewEvents_0036(InstanceID, SequenceNumber) WHERE LockedBy IS NULL;
CREATE INDEX IF NOT EXISTS IX_NewEvents_0037_ID_SeqNum_WHERE_LockedBy_NULL ON NewEvents_0037(InstanceID, SequenceNumber) WHERE LockedBy IS NULL;
CREATE INDEX IF NOT EXISTS IX_NewEvents_0038_ID_SeqNum_WHERE_LockedBy_NULL ON NewEvents_0038(InstanceID, SequenceNumber) WHERE LockedBy IS NULL;
CREATE INDEX IF NOT EXISTS IX_NewEvents_0039_ID_SeqNum_WHERE_LockedBy_NULL ON NewEvents_0039(InstanceID, SequenceNumber) WHERE LockedBy IS NULL;
CREATE INDEX IF NOT EXISTS IX_NewEvents_0040_ID_SeqNum_WHERE_LockedBy_NULL ON NewEvents_0040(InstanceID, SequenceNumber) WHERE LockedBy IS NULL;
CREATE INDEX IF NOT EXISTS IX_NewEvents_0041_ID_SeqNum_WHERE_LockedBy_NULL ON NewEvents_0041(InstanceID, SequenceNumber) WHERE LockedBy IS NULL;
CREATE INDEX IF NOT EXISTS IX_NewEvents_0042_ID_SeqNum_WHERE_LockedBy_NULL ON NewEvents_0042(InstanceID, SequenceNumber) WHERE LockedBy IS NULL;
CREATE INDEX IF NOT EXISTS IX_NewEvents_0043_ID_SeqNum_WHERE_LockedBy_NULL ON NewEvents_0043(InstanceID, SequenceNumber) WHERE LockedBy IS NULL;
CREATE INDEX IF NOT EXISTS IX_NewEvents_0044_ID_SeqNum_WHERE_LockedBy_NULL ON NewEvents_0044(InstanceID, SequenceNumber) WHERE LockedBy IS NULL;
CREATE INDEX IF NOT EXISTS IX_NewEvents_0045_ID_SeqNum_WHERE_LockedBy_NULL ON NewEvents_0045(InstanceID, SequenceNumber) WHERE LockedBy IS NULL;
CREATE INDEX IF NOT EXISTS IX_NewEvents_0046_ID_SeqNum_WHERE_LockedBy_NULL ON NewEvents_0046(InstanceID, SequenceNumber) WHERE LockedBy IS NULL;
CREATE INDEX IF NOT EXISTS IX_NewEvents_0047_ID_SeqNum_WHERE_LockedBy_NULL ON NewEvents_0047(InstanceID, SequenceNumber) WHERE LockedBy IS NULL;
CREATE INDEX IF NOT EXISTS IX_NewEvents_0048_ID_SeqNum_WHERE_LockedBy_NULL ON NewEvents_0048(InstanceID, SequenceNumber) WHERE LockedBy IS NULL;
CREATE INDEX IF NOT EXISTS IX_NewEvents_0049_ID_SeqNum_WHERE_LockedBy_NULL ON NewEvents_0049(InstanceID, SequenceNumber) WHERE LockedBy IS NULL;
CREATE INDEX IF NOT EXISTS IX_NewEvents_0050_ID_SeqNum_WHERE_LockedBy_NULL ON NewEvents_0050(InstanceID, SequenceNumber) WHERE LockedBy IS NULL;
CREATE INDEX IF NOT EXISTS IX_NewEvents_0051_ID_SeqNum_WHERE_LockedBy_NULL ON NewEvents_0051(InstanceID, SequenceNumber) WHERE LockedBy IS NULL;
CREATE INDEX IF NOT EXISTS IX_NewEvents_0052_ID_SeqNum_WHERE_LockedBy_NULL ON NewEvents_0052(InstanceID, SequenceNumber) WHERE LockedBy IS NULL;
CREATE INDEX IF NOT EXISTS IX_NewEvents_0053_ID_SeqNum_WHERE_LockedBy_NULL ON NewEvents_0053(InstanceID, SequenceNumber) WHERE LockedBy IS NULL;
CREATE INDEX IF NOT EXISTS IX_NewEvents_0054_ID_SeqNum_WHERE_LockedBy_NULL ON NewEvents_0054(InstanceID, SequenceNumber) WHERE LockedBy IS NULL;
CREATE INDEX IF NOT EXISTS IX_NewEvents_0055_ID_SeqNum_WHERE_LockedBy_NULL ON NewEvents_0055(InstanceID, SequenceNumber) WHERE LockedBy IS NULL;
CREATE INDEX IF NOT EXISTS IX_NewEvents_0056_ID_SeqNum_WHERE_LockedBy_NULL ON NewEvents_0056(InstanceID, SequenceNumber) WHERE LockedBy IS NULL;
CREATE INDEX IF NOT EXISTS IX_NewEvents_0057_ID_SeqNum_WHERE_LockedBy_NULL ON NewEvents_0057(InstanceID, SequenceNumber) WHERE LockedBy IS NULL;
CREATE INDEX IF NOT EXISTS IX_NewEvents_0058_ID_SeqNum_WHERE_LockedBy_NULL ON NewEvents_0058(InstanceID, SequenceNumber) WHERE LockedBy IS NULL;
CREATE INDEX IF NOT EXISTS IX_NewEvents_0059_ID_SeqNum_WHERE_LockedBy_NULL ON NewEvents_0059(InstanceID, SequenceNumber) WHERE LockedBy IS NULL;
CREATE INDEX IF NOT EXISTS IX_NewEvents_0060_ID_SeqNum_WHERE_LockedBy_NULL ON NewEvents_0060(InstanceID, SequenceNumber) WHERE LockedBy IS NULL;
CREATE INDEX IF NOT EXISTS IX_NewEvents_0061_ID_SeqNum_WHERE_LockedBy_NULL ON NewEvents_0061(InstanceID, SequenceNumber) WHERE LockedBy IS NULL;
CREATE INDEX IF NOT EXISTS IX_NewEvents_0062_ID_SeqNum_WHERE_LockedBy_NULL ON NewEvents_0062(InstanceID, SequenceNumber) WHERE LockedBy IS NULL;
CREATE INDEX IF NOT EXISTS IX_NewEvents_0063_ID_SeqNum_WHERE_LockedBy_NULL ON NewEvents_0063(InstanceID, SequenceNumber) WHERE LockedBy IS NULL;

CREATE INDEX IF NOT EXISTS IX_NewEvents_0000_VisibleTime_WHERE_VisibleTime_IS_NOT_NULL ON NewEvents_0000(VisibleTime) WHERE VisibleTime IS NOT NULL;
CREATE INDEX IF NOT EXISTS IX_NewEvents_0001_VisibleTime_WHERE_VisibleTime_IS_NOT_NULL ON NewEvents_0001(VisibleTime) WHERE VisibleTime IS NOT NULL;
CREATE INDEX IF NOT EXISTS IX_NewEvents_0002_VisibleTime_WHERE_VisibleTime_IS_NOT_NULL ON NewEvents_0002(VisibleTime) WHERE VisibleTime IS NOT NULL;
CREATE INDEX IF NOT EXISTS IX_NewEvents_0003_VisibleTime_WHERE_VisibleTime_IS_NOT_NULL ON NewEvents_0003(VisibleTime) WHERE VisibleTime IS NOT NULL;
CREATE INDEX IF NOT EXISTS IX_NewEvents_0004_VisibleTime_WHERE_VisibleTime_IS_NOT_NULL ON NewEvents_0004(VisibleTime) WHERE VisibleTime IS NOT NULL;
CREATE INDEX IF NOT EXISTS IX_NewEvents_0005_VisibleTime_WHERE_VisibleTime_IS_NOT_NULL ON NewEvents_0005(VisibleTime) WHERE VisibleTime IS NOT NULL;
CREATE INDEX IF NOT EXISTS IX_NewEvents_0006_VisibleTime_WHERE_VisibleTime_IS_NOT_NULL ON NewEvents_0006(VisibleTime) WHERE VisibleTime IS NOT NULL;
CREATE INDEX IF NOT EXISTS IX_NewEvents_0007_VisibleTime_WHERE_VisibleTime_IS_NOT_NULL ON NewEvents_0007(VisibleTime) WHERE VisibleTime IS NOT NULL;
CREATE INDEX IF NOT EXISTS IX_NewEvents_0008_VisibleTime_WHERE_VisibleTime_IS_NOT_NULL ON NewEvents_0008(VisibleTime) WHERE VisibleTime IS NOT NULL;
CREATE INDEX IF NOT EXISTS IX_NewEvents_0009_VisibleTime_WHERE_VisibleTime_IS_NOT_NULL ON NewEvents_0009(VisibleTime) WHERE VisibleTime IS NOT NULL;
CREATE INDEX IF NOT EXISTS IX_NewEvents_0010_VisibleTime_WHERE_VisibleTime_IS_NOT_NULL ON NewEvents_0010(VisibleTime) WHERE VisibleTime IS NOT NULL;
CREATE INDEX IF NOT EXISTS IX_NewEvents_0011_VisibleTime_WHERE_VisibleTime_IS_NOT_NULL ON NewEvents_0011(VisibleTime) WHERE VisibleTime IS NOT NULL;
CREATE INDEX IF NOT EXISTS IX_NewEvents_0012_VisibleTime_WHERE_VisibleTime_IS_NOT_NULL ON NewEvents_0012(VisibleTime) WHERE VisibleTime IS NOT NULL;
CREATE INDEX IF NOT EXISTS IX_NewEvents_0013_VisibleTime_WHERE_VisibleTime_IS_NOT_NULL ON NewEvents_0013(VisibleTime) WHERE VisibleTime IS NOT NULL;
CREATE INDEX IF NOT EXISTS IX_NewEvents_0014_VisibleTime_WHERE_VisibleTime_IS_NOT_NULL ON NewEvents_0014(VisibleTime) WHERE VisibleTime IS NOT NULL;
CREATE INDEX IF NOT EXISTS IX_NewEvents_0015_VisibleTime_WHERE_VisibleTime_IS_NOT_NULL ON NewEvents_0015(VisibleTime) WHERE VisibleTime IS NOT NULL;
CREATE INDEX IF NOT EXISTS IX_NewEvents_0016_VisibleTime_WHERE_VisibleTime_IS_NOT_NULL ON NewEvents_0016(VisibleTime) WHERE VisibleTime IS NOT NULL;
CREATE INDEX IF NOT EXISTS IX_NewEvents_0017_VisibleTime_WHERE_VisibleTime_IS_NOT_NULL ON NewEvents_0017(VisibleTime) WHERE VisibleTime IS NOT NULL;
CREATE INDEX IF NOT EXISTS IX_NewEvents_0018_VisibleTime_WHERE_VisibleTime_IS_NOT_NULL ON NewEvents_0018(VisibleTime) WHERE VisibleTime IS NOT NULL;
CREATE INDEX IF NOT EXISTS IX_NewEvents_0019_VisibleTime_WHERE_VisibleTime_IS_NOT_NULL ON NewEvents_0019(VisibleTime) WHERE VisibleTime IS NOT NULL;
CREATE INDEX IF NOT EXISTS IX_NewEvents_0020_VisibleTime_WHERE_VisibleTime_IS_NOT_NULL ON NewEvents_0020(VisibleTime) WHERE VisibleTime IS NOT NULL;
CREATE INDEX IF NOT EXISTS IX_NewEvents_0021_VisibleTime_WHERE_VisibleTime_IS_NOT_NULL ON NewEvents_0021(VisibleTime) WHERE VisibleTime IS NOT NULL;
CREATE INDEX IF NOT EXISTS IX_NewEvents_0022_VisibleTime_WHERE_VisibleTime_IS_NOT_NULL ON NewEvents_0022(VisibleTime) WHERE VisibleTime IS NOT NULL;
CREATE INDEX IF NOT EXISTS IX_NewEvents_0023_VisibleTime_WHERE_VisibleTime_IS_NOT_NULL ON NewEvents_0023(VisibleTime) WHERE VisibleTime IS NOT NULL;
CREATE INDEX IF NOT EXISTS IX_NewEvents_0024_VisibleTime_WHERE_VisibleTime_IS_NOT_NULL ON NewEvents_0024(VisibleTime) WHERE VisibleTime IS NOT NULL;
CREATE INDEX IF NOT EXISTS IX_NewEvents_0025_VisibleTime_WHERE_VisibleTime_IS_NOT_NULL ON NewEvents_0025(VisibleTime) WHERE VisibleTime IS NOT NULL;
CREATE INDEX IF NOT EXISTS IX_NewEvents_0026_VisibleTime_WHERE_VisibleTime_IS_NOT_NULL ON NewEvents_0026(VisibleTime) WHERE VisibleTime IS NOT NULL;
CREATE INDEX IF NOT EXISTS IX_NewEvents_0027_VisibleTime_WHERE_VisibleTime_IS_NOT_NULL ON NewEvents_0027(VisibleTime) WHERE VisibleTime IS NOT NULL;
CREATE INDEX IF NOT EXISTS IX_NewEvents_0028_VisibleTime_WHERE_VisibleTime_IS_NOT_NULL ON NewEvents_0028(VisibleTime) WHERE VisibleTime IS NOT NULL;
CREATE INDEX IF NOT EXISTS IX_NewEvents_0029_VisibleTime_WHERE_VisibleTime_IS_NOT_NULL ON NewEvents_0029(VisibleTime) WHERE VisibleTime IS NOT NULL;
CREATE INDEX IF NOT EXISTS IX_NewEvents_0030_VisibleTime_WHERE_VisibleTime_IS_NOT_NULL ON NewEvents_0030(VisibleTime) WHERE VisibleTime IS NOT NULL;
CREATE INDEX IF NOT EXISTS IX_NewEvents_0031_VisibleTime_WHERE_VisibleTime_IS_NOT_NULL ON NewEvents_0031(VisibleTime) WHERE VisibleTime IS NOT NULL;
CREATE INDEX IF NOT EXISTS IX_NewEvents_0032_VisibleTime_WHERE_VisibleTime_IS_NOT_NULL ON NewEvents_0032(VisibleTime) WHERE VisibleTime IS NOT NULL;
CREATE INDEX IF NOT EXISTS IX_NewEvents_0033_VisibleTime_WHERE_VisibleTime_IS_NOT_NULL ON NewEvents_0033(VisibleTime) WHERE VisibleTime IS NOT NULL;
CREATE INDEX IF NOT EXISTS IX_NewEvents_0034_VisibleTime_WHERE_VisibleTime_IS_NOT_NULL ON NewEvents_0034(VisibleTime) WHERE VisibleTime IS NOT NULL;
CREATE INDEX IF NOT EXISTS IX_NewEvents_0035_VisibleTime_WHERE_VisibleTime_IS_NOT_NULL ON NewEvents_0035(VisibleTime) WHERE VisibleTime IS NOT NULL;
CREATE INDEX IF NOT EXISTS IX_NewEvents_0036_VisibleTime_WHERE_VisibleTime_IS_NOT_NULL ON NewEvents_0036(VisibleTime) WHERE VisibleTime IS NOT NULL;
CREATE INDEX IF NOT EXISTS IX_NewEvents_0037_VisibleTime_WHERE_VisibleTime_IS_NOT_NULL ON NewEvents_0037(VisibleTime) WHERE VisibleTime IS NOT NULL;
CREATE INDEX IF NOT EXISTS IX_NewEvents_0038_VisibleTime_WHERE_VisibleTime_IS_NOT_NULL ON NewEvents_0038(VisibleTime) WHERE VisibleTime IS NOT NULL;
CREATE INDEX IF NOT EXISTS IX_NewEvents_0039_VisibleTime_WHERE_VisibleTime_IS_NOT_NULL ON NewEvents_0039(VisibleTime) WHERE VisibleTime IS NOT NULL;
CREATE INDEX IF NOT EXISTS IX_NewEvents_0040_VisibleTime_WHERE_VisibleTime_IS_NOT_NULL ON NewEvents_0040(VisibleTime) WHERE VisibleTime IS NOT NULL;
CREATE INDEX IF NOT EXISTS IX_NewEvents_0041_VisibleTime_WHERE_VisibleTime_IS_NOT_NULL ON NewEvents_0041(VisibleTime) WHERE VisibleTime IS NOT NULL;
CREATE INDEX IF NOT EXISTS IX_NewEvents_0042_VisibleTime_WHERE_VisibleTime_IS_NOT_NULL ON NewEvents_0042(VisibleTime) WHERE VisibleTime IS NOT NULL;
CREATE INDEX IF NOT EXISTS IX_NewEvents_0043_VisibleTime_WHERE_VisibleTime_IS_NOT_NULL ON NewEvents_0043(VisibleTime) WHERE VisibleTime IS NOT NULL;
CREATE INDEX IF NOT EXISTS IX_NewEvents_0044_VisibleTime_WHERE_VisibleTime_IS_NOT_NULL ON NewEvents_0044(VisibleTime) WHERE VisibleTime IS NOT NULL;
CREATE INDEX IF NOT EXISTS IX_NewEvents_0045_VisibleTime_WHERE_VisibleTime_IS_NOT_NULL ON NewEvents_0045(VisibleTime) WHERE VisibleTime IS NOT NULL;
CREATE INDEX IF NOT EXISTS IX_NewEvents_0046_VisibleTime_WHERE_VisibleTime_IS_NOT_NULL ON NewEvents_0046(VisibleTime) WHERE VisibleTime IS NOT NULL;
CREATE INDEX IF NOT EXISTS IX_NewEvents_0047_VisibleTime_WHERE_VisibleTime_IS_NOT_NULL ON NewEvents_0047(VisibleTime) WHERE VisibleTime IS NOT NULL;
CREATE INDEX IF NOT EXISTS IX_NewEvents_0048_VisibleTime_WHERE_VisibleTime_IS_NOT_NULL ON NewEvents_0048(VisibleTime) WHERE VisibleTime IS NOT NULL;
CREATE INDEX IF NOT EXISTS IX_NewEvents_0049_VisibleTime_WHERE_VisibleTime_IS_NOT_NULL ON NewEvents_0049(VisibleTime) WHERE VisibleTime IS NOT NULL;
CREATE INDEX IF NOT EXISTS IX_NewEvents_0050_VisibleTime_WHERE_VisibleTime_IS_NOT_NULL ON NewEvents_0050(VisibleTime) WHERE VisibleTime IS NOT NULL;
CREATE INDEX IF NOT EXISTS IX_NewEvents_0051_VisibleTime_WHERE_VisibleTime_IS_NOT_NULL ON NewEvents_0051(VisibleTime) WHERE VisibleTime IS NOT NULL;
CREATE INDEX IF NOT EXISTS IX_NewEvents_0052_VisibleTime_WHERE_VisibleTime_IS_NOT_NULL ON NewEvents_0052(VisibleTime) WHERE VisibleTime IS NOT NULL;
CREATE INDEX IF NOT EXISTS IX_NewEvents_0053_VisibleTime_WHERE_VisibleTime_IS_NOT_NULL ON NewEvents_0053(VisibleTime) WHERE VisibleTime IS NOT NULL;
CREATE INDEX IF NOT EXISTS IX_NewEvents_0054_VisibleTime_WHERE_VisibleTime_IS_NOT_NULL ON NewEvents_0054(VisibleTime) WHERE VisibleTime IS NOT NULL;
CREATE INDEX IF NOT EXISTS IX_NewEvents_0055_VisibleTime_WHERE_VisibleTime_IS_NOT_NULL ON NewEvents_0055(VisibleTime) WHERE VisibleTime IS NOT NULL;
CREATE INDEX IF NOT EXISTS IX_NewEvents_0056_VisibleTime_WHERE_VisibleTime_IS_NOT_NULL ON NewEvents_0056(VisibleTime) WHERE VisibleTime IS NOT NULL;
CREATE INDEX IF NOT EXISTS IX_NewEvents_0057_VisibleTime_WHERE_VisibleTime_IS_NOT_NULL ON NewEvents_0057(VisibleTime) WHERE VisibleTime IS NOT NULL;
CREATE INDEX IF NOT EXISTS IX_NewEvents_0058_VisibleTime_WHERE_VisibleTime_IS_NOT_NULL ON NewEvents_0058(VisibleTime) WHERE VisibleTime IS NOT NULL;
CREATE INDEX IF NOT EXISTS IX_NewEvents_0059_VisibleTime_WHERE_VisibleTime_IS_NOT_NULL ON NewEvents_0059(VisibleTime) WHERE VisibleTime IS NOT NULL;
CREATE INDEX IF NOT EXISTS IX_NewEvents_0060_VisibleTime_WHERE_VisibleTime_IS_NOT_NULL ON NewEvents_0060(VisibleTime) WHERE VisibleTime IS NOT NULL;
CREATE INDEX IF NOT EXISTS IX_NewEvents_0061_VisibleTime_WHERE_VisibleTime_IS_NOT_NULL ON NewEvents_0061(VisibleTime) WHERE VisibleTime IS NOT NULL;
CREATE INDEX IF NOT EXISTS IX_NewEvents_0062_VisibleTime_WHERE_VisibleTime_IS_NOT_NULL ON NewEvents_0062(VisibleTime) WHERE VisibleTime IS NOT NULL;
CREATE INDEX IF NOT EXISTS IX_NewEvents_0063_VisibleTime_WHERE_VisibleTime_IS_NOT_NULL ON NewEvents_0063(VisibleTime) WHERE VisibleTime IS NOT NULL;

-- Composite index for EXISTS subquery: (InstanceID, VisibleTime)
CREATE INDEX IF NOT EXISTS IX_NewEvents_0000_ID_VisTime ON NewEvents_0000(InstanceID, VisibleTime);
CREATE INDEX IF NOT EXISTS IX_NewEvents_0001_ID_VisTime ON NewEvents_0001(InstanceID, VisibleTime);
CREATE INDEX IF NOT EXISTS IX_NewEvents_0002_ID_VisTime ON NewEvents_0002(InstanceID, VisibleTime);
CREATE INDEX IF NOT EXISTS IX_NewEvents_0003_ID_VisTime ON NewEvents_0003(InstanceID, VisibleTime);
CREATE INDEX IF NOT EXISTS IX_NewEvents_0004_ID_VisTime ON NewEvents_0004(InstanceID, VisibleTime);
CREATE INDEX IF NOT EXISTS IX_NewEvents_0005_ID_VisTime ON NewEvents_0005(InstanceID, VisibleTime);
CREATE INDEX IF NOT EXISTS IX_NewEvents_0006_ID_VisTime ON NewEvents_0006(InstanceID, VisibleTime);
CREATE INDEX IF NOT EXISTS IX_NewEvents_0007_ID_VisTime ON NewEvents_0007(InstanceID, VisibleTime);
CREATE INDEX IF NOT EXISTS IX_NewEvents_0008_ID_VisTime ON NewEvents_0008(InstanceID, VisibleTime);
CREATE INDEX IF NOT EXISTS IX_NewEvents_0009_ID_VisTime ON NewEvents_0009(InstanceID, VisibleTime);
CREATE INDEX IF NOT EXISTS IX_NewEvents_0010_ID_VisTime ON NewEvents_0010(InstanceID, VisibleTime);
CREATE INDEX IF NOT EXISTS IX_NewEvents_0011_ID_VisTime ON NewEvents_0011(InstanceID, VisibleTime);
CREATE INDEX IF NOT EXISTS IX_NewEvents_0012_ID_VisTime ON NewEvents_0012(InstanceID, VisibleTime);
CREATE INDEX IF NOT EXISTS IX_NewEvents_0013_ID_VisTime ON NewEvents_0013(InstanceID, VisibleTime);
CREATE INDEX IF NOT EXISTS IX_NewEvents_0014_ID_VisTime ON NewEvents_0014(InstanceID, VisibleTime);
CREATE INDEX IF NOT EXISTS IX_NewEvents_0015_ID_VisTime ON NewEvents_0015(InstanceID, VisibleTime);
CREATE INDEX IF NOT EXISTS IX_NewEvents_0016_ID_VisTime ON NewEvents_0016(InstanceID, VisibleTime);
CREATE INDEX IF NOT EXISTS IX_NewEvents_0017_ID_VisTime ON NewEvents_0017(InstanceID, VisibleTime);
CREATE INDEX IF NOT EXISTS IX_NewEvents_0018_ID_VisTime ON NewEvents_0018(InstanceID, VisibleTime);
CREATE INDEX IF NOT EXISTS IX_NewEvents_0019_ID_VisTime ON NewEvents_0019(InstanceID, VisibleTime);
CREATE INDEX IF NOT EXISTS IX_NewEvents_0020_ID_VisTime ON NewEvents_0020(InstanceID, VisibleTime);
CREATE INDEX IF NOT EXISTS IX_NewEvents_0021_ID_VisTime ON NewEvents_0021(InstanceID, VisibleTime);
CREATE INDEX IF NOT EXISTS IX_NewEvents_0022_ID_VisTime ON NewEvents_0022(InstanceID, VisibleTime);
CREATE INDEX IF NOT EXISTS IX_NewEvents_0023_ID_VisTime ON NewEvents_0023(InstanceID, VisibleTime);
CREATE INDEX IF NOT EXISTS IX_NewEvents_0024_ID_VisTime ON NewEvents_0024(InstanceID, VisibleTime);
CREATE INDEX IF NOT EXISTS IX_NewEvents_0025_ID_VisTime ON NewEvents_0025(InstanceID, VisibleTime);
CREATE INDEX IF NOT EXISTS IX_NewEvents_0026_ID_VisTime ON NewEvents_0026(InstanceID, VisibleTime);
CREATE INDEX IF NOT EXISTS IX_NewEvents_0027_ID_VisTime ON NewEvents_0027(InstanceID, VisibleTime);
CREATE INDEX IF NOT EXISTS IX_NewEvents_0028_ID_VisTime ON NewEvents_0028(InstanceID, VisibleTime);
CREATE INDEX IF NOT EXISTS IX_NewEvents_0029_ID_VisTime ON NewEvents_0029(InstanceID, VisibleTime);
CREATE INDEX IF NOT EXISTS IX_NewEvents_0030_ID_VisTime ON NewEvents_0030(InstanceID, VisibleTime);
CREATE INDEX IF NOT EXISTS IX_NewEvents_0031_ID_VisTime ON NewEvents_0031(InstanceID, VisibleTime);
CREATE INDEX IF NOT EXISTS IX_NewEvents_0032_ID_VisTime ON NewEvents_0032(InstanceID, VisibleTime);
CREATE INDEX IF NOT EXISTS IX_NewEvents_0033_ID_VisTime ON NewEvents_0033(InstanceID, VisibleTime);
CREATE INDEX IF NOT EXISTS IX_NewEvents_0034_ID_VisTime ON NewEvents_0034(InstanceID, VisibleTime);
CREATE INDEX IF NOT EXISTS IX_NewEvents_0035_ID_VisTime ON NewEvents_0035(InstanceID, VisibleTime);
CREATE INDEX IF NOT EXISTS IX_NewEvents_0036_ID_VisTime ON NewEvents_0036(InstanceID, VisibleTime);
CREATE INDEX IF NOT EXISTS IX_NewEvents_0037_ID_VisTime ON NewEvents_0037(InstanceID, VisibleTime);
CREATE INDEX IF NOT EXISTS IX_NewEvents_0038_ID_VisTime ON NewEvents_0038(InstanceID, VisibleTime);
CREATE INDEX IF NOT EXISTS IX_NewEvents_0039_ID_VisTime ON NewEvents_0039(InstanceID, VisibleTime);
CREATE INDEX IF NOT EXISTS IX_NewEvents_0040_ID_VisTime ON NewEvents_0040(InstanceID, VisibleTime);
CREATE INDEX IF NOT EXISTS IX_NewEvents_0041_ID_VisTime ON NewEvents_0041(InstanceID, VisibleTime);
CREATE INDEX IF NOT EXISTS IX_NewEvents_0042_ID_VisTime ON NewEvents_0042(InstanceID, VisibleTime);
CREATE INDEX IF NOT EXISTS IX_NewEvents_0043_ID_VisTime ON NewEvents_0043(InstanceID, VisibleTime);
CREATE INDEX IF NOT EXISTS IX_NewEvents_0044_ID_VisTime ON NewEvents_0044(InstanceID, VisibleTime);
CREATE INDEX IF NOT EXISTS IX_NewEvents_0045_ID_VisTime ON NewEvents_0045(InstanceID, VisibleTime);
CREATE INDEX IF NOT EXISTS IX_NewEvents_0046_ID_VisTime ON NewEvents_0046(InstanceID, VisibleTime);
CREATE INDEX IF NOT EXISTS IX_NewEvents_0047_ID_VisTime ON NewEvents_0047(InstanceID, VisibleTime);
CREATE INDEX IF NOT EXISTS IX_NewEvents_0048_ID_VisTime ON NewEvents_0048(InstanceID, VisibleTime);
CREATE INDEX IF NOT EXISTS IX_NewEvents_0049_ID_VisTime ON NewEvents_0049(InstanceID, VisibleTime);
CREATE INDEX IF NOT EXISTS IX_NewEvents_0050_ID_VisTime ON NewEvents_0050(InstanceID, VisibleTime);
CREATE INDEX IF NOT EXISTS IX_NewEvents_0051_ID_VisTime ON NewEvents_0051(InstanceID, VisibleTime);
CREATE INDEX IF NOT EXISTS IX_NewEvents_0052_ID_VisTime ON NewEvents_0052(InstanceID, VisibleTime);
CREATE INDEX IF NOT EXISTS IX_NewEvents_0053_ID_VisTime ON NewEvents_0053(InstanceID, VisibleTime);
CREATE INDEX IF NOT EXISTS IX_NewEvents_0054_ID_VisTime ON NewEvents_0054(InstanceID, VisibleTime);
CREATE INDEX IF NOT EXISTS IX_NewEvents_0055_ID_VisTime ON NewEvents_0055(InstanceID, VisibleTime);
CREATE INDEX IF NOT EXISTS IX_NewEvents_0056_ID_VisTime ON NewEvents_0056(InstanceID, VisibleTime);
CREATE INDEX IF NOT EXISTS IX_NewEvents_0057_ID_VisTime ON NewEvents_0057(InstanceID, VisibleTime);
CREATE INDEX IF NOT EXISTS IX_NewEvents_0058_ID_VisTime ON NewEvents_0058(InstanceID, VisibleTime);
CREATE INDEX IF NOT EXISTS IX_NewEvents_0059_ID_VisTime ON NewEvents_0059(InstanceID, VisibleTime);
CREATE INDEX IF NOT EXISTS IX_NewEvents_0060_ID_VisTime ON NewEvents_0060(InstanceID, VisibleTime);
CREATE INDEX IF NOT EXISTS IX_NewEvents_0061_ID_VisTime ON NewEvents_0061(InstanceID, VisibleTime);
CREATE INDEX IF NOT EXISTS IX_NewEvents_0062_ID_VisTime ON NewEvents_0062(InstanceID, VisibleTime);
CREATE INDEX IF NOT EXISTS IX_NewEvents_0063_ID_VisTime ON NewEvents_0063(InstanceID, VisibleTime);

CREATE INDEX IF NOT EXISTS IX_NewEvents_0000_ID_VisTime_SeqNum_WHERE_VisTime_NULL ON NewEvents_0000(InstanceID, VisibleTime, SequenceNumber) WHERE VisibleTime IS NULL;
CREATE INDEX IF NOT EXISTS IX_NewEvents_0001_ID_VisTime_SeqNum_WHERE_VisTime_NULL ON NewEvents_0001(InstanceID, VisibleTime, SequenceNumber) WHERE VisibleTime IS NULL;
CREATE INDEX IF NOT EXISTS IX_NewEvents_0002_ID_VisTime_SeqNum_WHERE_VisTime_NULL ON NewEvents_0002(InstanceID, VisibleTime, SequenceNumber) WHERE VisibleTime IS NULL;
CREATE INDEX IF NOT EXISTS IX_NewEvents_0003_ID_VisTime_SeqNum_WHERE_VisTime_NULL ON NewEvents_0003(InstanceID, VisibleTime, SequenceNumber) WHERE VisibleTime IS NULL;
CREATE INDEX IF NOT EXISTS IX_NewEvents_0004_ID_VisTime_SeqNum_WHERE_VisTime_NULL ON NewEvents_0004(InstanceID, VisibleTime, SequenceNumber) WHERE VisibleTime IS NULL;
CREATE INDEX IF NOT EXISTS IX_NewEvents_0005_ID_VisTime_SeqNum_WHERE_VisTime_NULL ON NewEvents_0005(InstanceID, VisibleTime, SequenceNumber) WHERE VisibleTime IS NULL;
CREATE INDEX IF NOT EXISTS IX_NewEvents_0006_ID_VisTime_SeqNum_WHERE_VisTime_NULL ON NewEvents_0006(InstanceID, VisibleTime, SequenceNumber) WHERE VisibleTime IS NULL;
CREATE INDEX IF NOT EXISTS IX_NewEvents_0007_ID_VisTime_SeqNum_WHERE_VisTime_NULL ON NewEvents_0007(InstanceID, VisibleTime, SequenceNumber) WHERE VisibleTime IS NULL;
CREATE INDEX IF NOT EXISTS IX_NewEvents_0008_ID_VisTime_SeqNum_WHERE_VisTime_NULL ON NewEvents_0008(InstanceID, VisibleTime, SequenceNumber) WHERE VisibleTime IS NULL;
CREATE INDEX IF NOT EXISTS IX_NewEvents_0009_ID_VisTime_SeqNum_WHERE_VisTime_NULL ON NewEvents_0009(InstanceID, VisibleTime, SequenceNumber) WHERE VisibleTime IS NULL;
CREATE INDEX IF NOT EXISTS IX_NewEvents_0010_ID_VisTime_SeqNum_WHERE_VisTime_NULL ON NewEvents_0010(InstanceID, VisibleTime, SequenceNumber) WHERE VisibleTime IS NULL;
CREATE INDEX IF NOT EXISTS IX_NewEvents_0011_ID_VisTime_SeqNum_WHERE_VisTime_NULL ON NewEvents_0011(InstanceID, VisibleTime, SequenceNumber) WHERE VisibleTime IS NULL;
CREATE INDEX IF NOT EXISTS IX_NewEvents_0012_ID_VisTime_SeqNum_WHERE_VisTime_NULL ON NewEvents_0012(InstanceID, VisibleTime, SequenceNumber) WHERE VisibleTime IS NULL;
CREATE INDEX IF NOT EXISTS IX_NewEvents_0013_ID_VisTime_SeqNum_WHERE_VisTime_NULL ON NewEvents_0013(InstanceID, VisibleTime, SequenceNumber) WHERE VisibleTime IS NULL;
CREATE INDEX IF NOT EXISTS IX_NewEvents_0014_ID_VisTime_SeqNum_WHERE_VisTime_NULL ON NewEvents_0014(InstanceID, VisibleTime, SequenceNumber) WHERE VisibleTime IS NULL;
CREATE INDEX IF NOT EXISTS IX_NewEvents_0015_ID_VisTime_SeqNum_WHERE_VisTime_NULL ON NewEvents_0015(InstanceID, VisibleTime, SequenceNumber) WHERE VisibleTime IS NULL;
CREATE INDEX IF NOT EXISTS IX_NewEvents_0016_ID_VisTime_SeqNum_WHERE_VisTime_NULL ON NewEvents_0016(InstanceID, VisibleTime, SequenceNumber) WHERE VisibleTime IS NULL;
CREATE INDEX IF NOT EXISTS IX_NewEvents_0017_ID_VisTime_SeqNum_WHERE_VisTime_NULL ON NewEvents_0017(InstanceID, VisibleTime, SequenceNumber) WHERE VisibleTime IS NULL;
CREATE INDEX IF NOT EXISTS IX_NewEvents_0018_ID_VisTime_SeqNum_WHERE_VisTime_NULL ON NewEvents_0018(InstanceID, VisibleTime, SequenceNumber) WHERE VisibleTime IS NULL;
CREATE INDEX IF NOT EXISTS IX_NewEvents_0019_ID_VisTime_SeqNum_WHERE_VisTime_NULL ON NewEvents_0019(InstanceID, VisibleTime, SequenceNumber) WHERE VisibleTime IS NULL;
CREATE INDEX IF NOT EXISTS IX_NewEvents_0020_ID_VisTime_SeqNum_WHERE_VisTime_NULL ON NewEvents_0020(InstanceID, VisibleTime, SequenceNumber) WHERE VisibleTime IS NULL;
CREATE INDEX IF NOT EXISTS IX_NewEvents_0021_ID_VisTime_SeqNum_WHERE_VisTime_NULL ON NewEvents_0021(InstanceID, VisibleTime, SequenceNumber) WHERE VisibleTime IS NULL;
CREATE INDEX IF NOT EXISTS IX_NewEvents_0022_ID_VisTime_SeqNum_WHERE_VisTime_NULL ON NewEvents_0022(InstanceID, VisibleTime, SequenceNumber) WHERE VisibleTime IS NULL;
CREATE INDEX IF NOT EXISTS IX_NewEvents_0023_ID_VisTime_SeqNum_WHERE_VisTime_NULL ON NewEvents_0023(InstanceID, VisibleTime, SequenceNumber) WHERE VisibleTime IS NULL;
CREATE INDEX IF NOT EXISTS IX_NewEvents_0024_ID_VisTime_SeqNum_WHERE_VisTime_NULL ON NewEvents_0024(InstanceID, VisibleTime, SequenceNumber) WHERE VisibleTime IS NULL;
CREATE INDEX IF NOT EXISTS IX_NewEvents_0025_ID_VisTime_SeqNum_WHERE_VisTime_NULL ON NewEvents_0025(InstanceID, VisibleTime, SequenceNumber) WHERE VisibleTime IS NULL;
CREATE INDEX IF NOT EXISTS IX_NewEvents_0026_ID_VisTime_SeqNum_WHERE_VisTime_NULL ON NewEvents_0026(InstanceID, VisibleTime, SequenceNumber) WHERE VisibleTime IS NULL;
CREATE INDEX IF NOT EXISTS IX_NewEvents_0027_ID_VisTime_SeqNum_WHERE_VisTime_NULL ON NewEvents_0027(InstanceID, VisibleTime, SequenceNumber) WHERE VisibleTime IS NULL;
CREATE INDEX IF NOT EXISTS IX_NewEvents_0028_ID_VisTime_SeqNum_WHERE_VisTime_NULL ON NewEvents_0028(InstanceID, VisibleTime, SequenceNumber) WHERE VisibleTime IS NULL;
CREATE INDEX IF NOT EXISTS IX_NewEvents_0029_ID_VisTime_SeqNum_WHERE_VisTime_NULL ON NewEvents_0029(InstanceID, VisibleTime, SequenceNumber) WHERE VisibleTime IS NULL;
CREATE INDEX IF NOT EXISTS IX_NewEvents_0030_ID_VisTime_SeqNum_WHERE_VisTime_NULL ON NewEvents_0030(InstanceID, VisibleTime, SequenceNumber) WHERE VisibleTime IS NULL;
CREATE INDEX IF NOT EXISTS IX_NewEvents_0031_ID_VisTime_SeqNum_WHERE_VisTime_NULL ON NewEvents_0031(InstanceID, VisibleTime, SequenceNumber) WHERE VisibleTime IS NULL;
CREATE INDEX IF NOT EXISTS IX_NewEvents_0032_ID_VisTime_SeqNum_WHERE_VisTime_NULL ON NewEvents_0032(InstanceID, VisibleTime, SequenceNumber) WHERE VisibleTime IS NULL;
CREATE INDEX IF NOT EXISTS IX_NewEvents_0033_ID_VisTime_SeqNum_WHERE_VisTime_NULL ON NewEvents_0033(InstanceID, VisibleTime, SequenceNumber) WHERE VisibleTime IS NULL;
CREATE INDEX IF NOT EXISTS IX_NewEvents_0034_ID_VisTime_SeqNum_WHERE_VisTime_NULL ON NewEvents_0034(InstanceID, VisibleTime, SequenceNumber) WHERE VisibleTime IS NULL;
CREATE INDEX IF NOT EXISTS IX_NewEvents_0035_ID_VisTime_SeqNum_WHERE_VisTime_NULL ON NewEvents_0035(InstanceID, VisibleTime, SequenceNumber) WHERE VisibleTime IS NULL;
CREATE INDEX IF NOT EXISTS IX_NewEvents_0036_ID_VisTime_SeqNum_WHERE_VisTime_NULL ON NewEvents_0036(InstanceID, VisibleTime, SequenceNumber) WHERE VisibleTime IS NULL;
CREATE INDEX IF NOT EXISTS IX_NewEvents_0037_ID_VisTime_SeqNum_WHERE_VisTime_NULL ON NewEvents_0037(InstanceID, VisibleTime, SequenceNumber) WHERE VisibleTime IS NULL;
CREATE INDEX IF NOT EXISTS IX_NewEvents_0038_ID_VisTime_SeqNum_WHERE_VisTime_NULL ON NewEvents_0038(InstanceID, VisibleTime, SequenceNumber) WHERE VisibleTime IS NULL;
CREATE INDEX IF NOT EXISTS IX_NewEvents_0039_ID_VisTime_SeqNum_WHERE_VisTime_NULL ON NewEvents_0039(InstanceID, VisibleTime, SequenceNumber) WHERE VisibleTime IS NULL;
CREATE INDEX IF NOT EXISTS IX_NewEvents_0040_ID_VisTime_SeqNum_WHERE_VisTime_NULL ON NewEvents_0040(InstanceID, VisibleTime, SequenceNumber) WHERE VisibleTime IS NULL;
CREATE INDEX IF NOT EXISTS IX_NewEvents_0041_ID_VisTime_SeqNum_WHERE_VisTime_NULL ON NewEvents_0041(InstanceID, VisibleTime, SequenceNumber) WHERE VisibleTime IS NULL;
CREATE INDEX IF NOT EXISTS IX_NewEvents_0042_ID_VisTime_SeqNum_WHERE_VisTime_NULL ON NewEvents_0042(InstanceID, VisibleTime, SequenceNumber) WHERE VisibleTime IS NULL;
CREATE INDEX IF NOT EXISTS IX_NewEvents_0043_ID_VisTime_SeqNum_WHERE_VisTime_NULL ON NewEvents_0043(InstanceID, VisibleTime, SequenceNumber) WHERE VisibleTime IS NULL;
CREATE INDEX IF NOT EXISTS IX_NewEvents_0044_ID_VisTime_SeqNum_WHERE_VisTime_NULL ON NewEvents_0044(InstanceID, VisibleTime, SequenceNumber) WHERE VisibleTime IS NULL;
CREATE INDEX IF NOT EXISTS IX_NewEvents_0045_ID_VisTime_SeqNum_WHERE_VisTime_NULL ON NewEvents_0045(InstanceID, VisibleTime, SequenceNumber) WHERE VisibleTime IS NULL;
CREATE INDEX IF NOT EXISTS IX_NewEvents_0046_ID_VisTime_SeqNum_WHERE_VisTime_NULL ON NewEvents_0046(InstanceID, VisibleTime, SequenceNumber) WHERE VisibleTime IS NULL;
CREATE INDEX IF NOT EXISTS IX_NewEvents_0047_ID_VisTime_SeqNum_WHERE_VisTime_NULL ON NewEvents_0047(InstanceID, VisibleTime, SequenceNumber) WHERE VisibleTime IS NULL;
CREATE INDEX IF NOT EXISTS IX_NewEvents_0048_ID_VisTime_SeqNum_WHERE_VisTime_NULL ON NewEvents_0048(InstanceID, VisibleTime, SequenceNumber) WHERE VisibleTime IS NULL;
CREATE INDEX IF NOT EXISTS IX_NewEvents_0049_ID_VisTime_SeqNum_WHERE_VisTime_NULL ON NewEvents_0049(InstanceID, VisibleTime, SequenceNumber) WHERE VisibleTime IS NULL;
CREATE INDEX IF NOT EXISTS IX_NewEvents_0050_ID_VisTime_SeqNum_WHERE_VisTime_NULL ON NewEvents_0050(InstanceID, VisibleTime, SequenceNumber) WHERE VisibleTime IS NULL;
CREATE INDEX IF NOT EXISTS IX_NewEvents_0051_ID_VisTime_SeqNum_WHERE_VisTime_NULL ON NewEvents_0051(InstanceID, VisibleTime, SequenceNumber) WHERE VisibleTime IS NULL;
CREATE INDEX IF NOT EXISTS IX_NewEvents_0052_ID_VisTime_SeqNum_WHERE_VisTime_NULL ON NewEvents_0052(InstanceID, VisibleTime, SequenceNumber) WHERE VisibleTime IS NULL;
CREATE INDEX IF NOT EXISTS IX_NewEvents_0053_ID_VisTime_SeqNum_WHERE_VisTime_NULL ON NewEvents_0053(InstanceID, VisibleTime, SequenceNumber) WHERE VisibleTime IS NULL;
CREATE INDEX IF NOT EXISTS IX_NewEvents_0054_ID_VisTime_SeqNum_WHERE_VisTime_NULL ON NewEvents_0054(InstanceID, VisibleTime, SequenceNumber) WHERE VisibleTime IS NULL;
CREATE INDEX IF NOT EXISTS IX_NewEvents_0055_ID_VisTime_SeqNum_WHERE_VisTime_NULL ON NewEvents_0055(InstanceID, VisibleTime, SequenceNumber) WHERE VisibleTime IS NULL;
CREATE INDEX IF NOT EXISTS IX_NewEvents_0056_ID_VisTime_SeqNum_WHERE_VisTime_NULL ON NewEvents_0056(InstanceID, VisibleTime, SequenceNumber) WHERE VisibleTime IS NULL;
CREATE INDEX IF NOT EXISTS IX_NewEvents_0057_ID_VisTime_SeqNum_WHERE_VisTime_NULL ON NewEvents_0057(InstanceID, VisibleTime, SequenceNumber) WHERE VisibleTime IS NULL;
CREATE INDEX IF NOT EXISTS IX_NewEvents_0058_ID_VisTime_SeqNum_WHERE_VisTime_NULL ON NewEvents_0058(InstanceID, VisibleTime, SequenceNumber) WHERE VisibleTime IS NULL;
CREATE INDEX IF NOT EXISTS IX_NewEvents_0059_ID_VisTime_SeqNum_WHERE_VisTime_NULL ON NewEvents_0059(InstanceID, VisibleTime, SequenceNumber) WHERE VisibleTime IS NULL;
CREATE INDEX IF NOT EXISTS IX_NewEvents_0060_ID_VisTime_SeqNum_WHERE_VisTime_NULL ON NewEvents_0060(InstanceID, VisibleTime, SequenceNumber) WHERE VisibleTime IS NULL;
CREATE INDEX IF NOT EXISTS IX_NewEvents_0061_ID_VisTime_SeqNum_WHERE_VisTime_NULL ON NewEvents_0061(InstanceID, VisibleTime, SequenceNumber) WHERE VisibleTime IS NULL;
CREATE INDEX IF NOT EXISTS IX_NewEvents_0062_ID_VisTime_SeqNum_WHERE_VisTime_NULL ON NewEvents_0062(InstanceID, VisibleTime, SequenceNumber) WHERE VisibleTime IS NULL;
CREATE INDEX IF NOT EXISTS IX_NewEvents_0063_ID_VisTime_SeqNum_WHERE_VisTime_NULL ON NewEvents_0063(InstanceID, VisibleTime, SequenceNumber) WHERE VisibleTime IS NULL;

CREATE INDEX IF NOT EXISTS IX_NewEvents_0000_ID_VisTime_Dequeue_WHERE_LockedBy_NULL ON NewEvents_0000(InstanceID, VisibleTime, DequeueCount) WHERE LockedBy IS NULL;
CREATE INDEX IF NOT EXISTS IX_NewEvents_0001_ID_VisTime_Dequeue_WHERE_LockedBy_NULL ON NewEvents_0001(InstanceID, VisibleTime, DequeueCount) WHERE LockedBy IS NULL;
CREATE INDEX IF NOT EXISTS IX_NewEvents_0002_ID_VisTime_Dequeue_WHERE_LockedBy_NULL ON NewEvents_0002(InstanceID, VisibleTime, DequeueCount) WHERE LockedBy IS NULL;
CREATE INDEX IF NOT EXISTS IX_NewEvents_0003_ID_VisTime_Dequeue_WHERE_LockedBy_NULL ON NewEvents_0003(InstanceID, VisibleTime, DequeueCount) WHERE LockedBy IS NULL;
CREATE INDEX IF NOT EXISTS IX_NewEvents_0004_ID_VisTime_Dequeue_WHERE_LockedBy_NULL ON NewEvents_0004(InstanceID, VisibleTime, DequeueCount) WHERE LockedBy IS NULL;
CREATE INDEX IF NOT EXISTS IX_NewEvents_0005_ID_VisTime_Dequeue_WHERE_LockedBy_NULL ON NewEvents_0005(InstanceID, VisibleTime, DequeueCount) WHERE LockedBy IS NULL;
CREATE INDEX IF NOT EXISTS IX_NewEvents_0006_ID_VisTime_Dequeue_WHERE_LockedBy_NULL ON NewEvents_0006(InstanceID, VisibleTime, DequeueCount) WHERE LockedBy IS NULL;
CREATE INDEX IF NOT EXISTS IX_NewEvents_0007_ID_VisTime_Dequeue_WHERE_LockedBy_NULL ON NewEvents_0007(InstanceID, VisibleTime, DequeueCount) WHERE LockedBy IS NULL;
CREATE INDEX IF NOT EXISTS IX_NewEvents_0008_ID_VisTime_Dequeue_WHERE_LockedBy_NULL ON NewEvents_0008(InstanceID, VisibleTime, DequeueCount) WHERE LockedBy IS NULL;
CREATE INDEX IF NOT EXISTS IX_NewEvents_0009_ID_VisTime_Dequeue_WHERE_LockedBy_NULL ON NewEvents_0009(InstanceID, VisibleTime, DequeueCount) WHERE LockedBy IS NULL;
CREATE INDEX IF NOT EXISTS IX_NewEvents_0010_ID_VisTime_Dequeue_WHERE_LockedBy_NULL ON NewEvents_0010(InstanceID, VisibleTime, DequeueCount) WHERE LockedBy IS NULL;
CREATE INDEX IF NOT EXISTS IX_NewEvents_0011_ID_VisTime_Dequeue_WHERE_LockedBy_NULL ON NewEvents_0011(InstanceID, VisibleTime, DequeueCount) WHERE LockedBy IS NULL;
CREATE INDEX IF NOT EXISTS IX_NewEvents_0012_ID_VisTime_Dequeue_WHERE_LockedBy_NULL ON NewEvents_0012(InstanceID, VisibleTime, DequeueCount) WHERE LockedBy IS NULL;
CREATE INDEX IF NOT EXISTS IX_NewEvents_0013_ID_VisTime_Dequeue_WHERE_LockedBy_NULL ON NewEvents_0013(InstanceID, VisibleTime, DequeueCount) WHERE LockedBy IS NULL;
CREATE INDEX IF NOT EXISTS IX_NewEvents_0014_ID_VisTime_Dequeue_WHERE_LockedBy_NULL ON NewEvents_0014(InstanceID, VisibleTime, DequeueCount) WHERE LockedBy IS NULL;
CREATE INDEX IF NOT EXISTS IX_NewEvents_0015_ID_VisTime_Dequeue_WHERE_LockedBy_NULL ON NewEvents_0015(InstanceID, VisibleTime, DequeueCount) WHERE LockedBy IS NULL;
CREATE INDEX IF NOT EXISTS IX_NewEvents_0016_ID_VisTime_Dequeue_WHERE_LockedBy_NULL ON NewEvents_0016(InstanceID, VisibleTime, DequeueCount) WHERE LockedBy IS NULL;
CREATE INDEX IF NOT EXISTS IX_NewEvents_0017_ID_VisTime_Dequeue_WHERE_LockedBy_NULL ON NewEvents_0017(InstanceID, VisibleTime, DequeueCount) WHERE LockedBy IS NULL;
CREATE INDEX IF NOT EXISTS IX_NewEvents_0018_ID_VisTime_Dequeue_WHERE_LockedBy_NULL ON NewEvents_0018(InstanceID, VisibleTime, DequeueCount) WHERE LockedBy IS NULL;
CREATE INDEX IF NOT EXISTS IX_NewEvents_0019_ID_VisTime_Dequeue_WHERE_LockedBy_NULL ON NewEvents_0019(InstanceID, VisibleTime, DequeueCount) WHERE LockedBy IS NULL;
CREATE INDEX IF NOT EXISTS IX_NewEvents_0020_ID_VisTime_Dequeue_WHERE_LockedBy_NULL ON NewEvents_0020(InstanceID, VisibleTime, DequeueCount) WHERE LockedBy IS NULL;
CREATE INDEX IF NOT EXISTS IX_NewEvents_0021_ID_VisTime_Dequeue_WHERE_LockedBy_NULL ON NewEvents_0021(InstanceID, VisibleTime, DequeueCount) WHERE LockedBy IS NULL;
CREATE INDEX IF NOT EXISTS IX_NewEvents_0022_ID_VisTime_Dequeue_WHERE_LockedBy_NULL ON NewEvents_0022(InstanceID, VisibleTime, DequeueCount) WHERE LockedBy IS NULL;
CREATE INDEX IF NOT EXISTS IX_NewEvents_0023_ID_VisTime_Dequeue_WHERE_LockedBy_NULL ON NewEvents_0023(InstanceID, VisibleTime, DequeueCount) WHERE LockedBy IS NULL;
CREATE INDEX IF NOT EXISTS IX_NewEvents_0024_ID_VisTime_Dequeue_WHERE_LockedBy_NULL ON NewEvents_0024(InstanceID, VisibleTime, DequeueCount) WHERE LockedBy IS NULL;
CREATE INDEX IF NOT EXISTS IX_NewEvents_0025_ID_VisTime_Dequeue_WHERE_LockedBy_NULL ON NewEvents_0025(InstanceID, VisibleTime, DequeueCount) WHERE LockedBy IS NULL;
CREATE INDEX IF NOT EXISTS IX_NewEvents_0026_ID_VisTime_Dequeue_WHERE_LockedBy_NULL ON NewEvents_0026(InstanceID, VisibleTime, DequeueCount) WHERE LockedBy IS NULL;
CREATE INDEX IF NOT EXISTS IX_NewEvents_0027_ID_VisTime_Dequeue_WHERE_LockedBy_NULL ON NewEvents_0027(InstanceID, VisibleTime, DequeueCount) WHERE LockedBy IS NULL;
CREATE INDEX IF NOT EXISTS IX_NewEvents_0028_ID_VisTime_Dequeue_WHERE_LockedBy_NULL ON NewEvents_0028(InstanceID, VisibleTime, DequeueCount) WHERE LockedBy IS NULL;
CREATE INDEX IF NOT EXISTS IX_NewEvents_0029_ID_VisTime_Dequeue_WHERE_LockedBy_NULL ON NewEvents_0029(InstanceID, VisibleTime, DequeueCount) WHERE LockedBy IS NULL;
CREATE INDEX IF NOT EXISTS IX_NewEvents_0030_ID_VisTime_Dequeue_WHERE_LockedBy_NULL ON NewEvents_0030(InstanceID, VisibleTime, DequeueCount) WHERE LockedBy IS NULL;
CREATE INDEX IF NOT EXISTS IX_NewEvents_0031_ID_VisTime_Dequeue_WHERE_LockedBy_NULL ON NewEvents_0031(InstanceID, VisibleTime, DequeueCount) WHERE LockedBy IS NULL;
CREATE INDEX IF NOT EXISTS IX_NewEvents_0032_ID_VisTime_Dequeue_WHERE_LockedBy_NULL ON NewEvents_0032(InstanceID, VisibleTime, DequeueCount) WHERE LockedBy IS NULL;
CREATE INDEX IF NOT EXISTS IX_NewEvents_0033_ID_VisTime_Dequeue_WHERE_LockedBy_NULL ON NewEvents_0033(InstanceID, VisibleTime, DequeueCount) WHERE LockedBy IS NULL;
CREATE INDEX IF NOT EXISTS IX_NewEvents_0034_ID_VisTime_Dequeue_WHERE_LockedBy_NULL ON NewEvents_0034(InstanceID, VisibleTime, DequeueCount) WHERE LockedBy IS NULL;
CREATE INDEX IF NOT EXISTS IX_NewEvents_0035_ID_VisTime_Dequeue_WHERE_LockedBy_NULL ON NewEvents_0035(InstanceID, VisibleTime, DequeueCount) WHERE LockedBy IS NULL;
CREATE INDEX IF NOT EXISTS IX_NewEvents_0036_ID_VisTime_Dequeue_WHERE_LockedBy_NULL ON NewEvents_0036(InstanceID, VisibleTime, DequeueCount) WHERE LockedBy IS NULL;
CREATE INDEX IF NOT EXISTS IX_NewEvents_0037_ID_VisTime_Dequeue_WHERE_LockedBy_NULL ON NewEvents_0037(InstanceID, VisibleTime, DequeueCount) WHERE LockedBy IS NULL;
CREATE INDEX IF NOT EXISTS IX_NewEvents_0038_ID_VisTime_Dequeue_WHERE_LockedBy_NULL ON NewEvents_0038(InstanceID, VisibleTime, DequeueCount) WHERE LockedBy IS NULL;
CREATE INDEX IF NOT EXISTS IX_NewEvents_0039_ID_VisTime_Dequeue_WHERE_LockedBy_NULL ON NewEvents_0039(InstanceID, VisibleTime, DequeueCount) WHERE LockedBy IS NULL;
CREATE INDEX IF NOT EXISTS IX_NewEvents_0040_ID_VisTime_Dequeue_WHERE_LockedBy_NULL ON NewEvents_0040(InstanceID, VisibleTime, DequeueCount) WHERE LockedBy IS NULL;
CREATE INDEX IF NOT EXISTS IX_NewEvents_0041_ID_VisTime_Dequeue_WHERE_LockedBy_NULL ON NewEvents_0041(InstanceID, VisibleTime, DequeueCount) WHERE LockedBy IS NULL;
CREATE INDEX IF NOT EXISTS IX_NewEvents_0042_ID_VisTime_Dequeue_WHERE_LockedBy_NULL ON NewEvents_0042(InstanceID, VisibleTime, DequeueCount) WHERE LockedBy IS NULL;
CREATE INDEX IF NOT EXISTS IX_NewEvents_0043_ID_VisTime_Dequeue_WHERE_LockedBy_NULL ON NewEvents_0043(InstanceID, VisibleTime, DequeueCount) WHERE LockedBy IS NULL;
CREATE INDEX IF NOT EXISTS IX_NewEvents_0044_ID_VisTime_Dequeue_WHERE_LockedBy_NULL ON NewEvents_0044(InstanceID, VisibleTime, DequeueCount) WHERE LockedBy IS NULL;
CREATE INDEX IF NOT EXISTS IX_NewEvents_0045_ID_VisTime_Dequeue_WHERE_LockedBy_NULL ON NewEvents_0045(InstanceID, VisibleTime, DequeueCount) WHERE LockedBy IS NULL;
CREATE INDEX IF NOT EXISTS IX_NewEvents_0046_ID_VisTime_Dequeue_WHERE_LockedBy_NULL ON NewEvents_0046(InstanceID, VisibleTime, DequeueCount) WHERE LockedBy IS NULL;
CREATE INDEX IF NOT EXISTS IX_NewEvents_0047_ID_VisTime_Dequeue_WHERE_LockedBy_NULL ON NewEvents_0047(InstanceID, VisibleTime, DequeueCount) WHERE LockedBy IS NULL;
CREATE INDEX IF NOT EXISTS IX_NewEvents_0048_ID_VisTime_Dequeue_WHERE_LockedBy_NULL ON NewEvents_0048(InstanceID, VisibleTime, DequeueCount) WHERE LockedBy IS NULL;
CREATE INDEX IF NOT EXISTS IX_NewEvents_0049_ID_VisTime_Dequeue_WHERE_LockedBy_NULL ON NewEvents_0049(InstanceID, VisibleTime, DequeueCount) WHERE LockedBy IS NULL;
CREATE INDEX IF NOT EXISTS IX_NewEvents_0050_ID_VisTime_Dequeue_WHERE_LockedBy_NULL ON NewEvents_0050(InstanceID, VisibleTime, DequeueCount) WHERE LockedBy IS NULL;
CREATE INDEX IF NOT EXISTS IX_NewEvents_0051_ID_VisTime_Dequeue_WHERE_LockedBy_NULL ON NewEvents_0051(InstanceID, VisibleTime, DequeueCount) WHERE LockedBy IS NULL;
CREATE INDEX IF NOT EXISTS IX_NewEvents_0052_ID_VisTime_Dequeue_WHERE_LockedBy_NULL ON NewEvents_0052(InstanceID, VisibleTime, DequeueCount) WHERE LockedBy IS NULL;
CREATE INDEX IF NOT EXISTS IX_NewEvents_0053_ID_VisTime_Dequeue_WHERE_LockedBy_NULL ON NewEvents_0053(InstanceID, VisibleTime, DequeueCount) WHERE LockedBy IS NULL;
CREATE INDEX IF NOT EXISTS IX_NewEvents_0054_ID_VisTime_Dequeue_WHERE_LockedBy_NULL ON NewEvents_0054(InstanceID, VisibleTime, DequeueCount) WHERE LockedBy IS NULL;
CREATE INDEX IF NOT EXISTS IX_NewEvents_0055_ID_VisTime_Dequeue_WHERE_LockedBy_NULL ON NewEvents_0055(InstanceID, VisibleTime, DequeueCount) WHERE LockedBy IS NULL;
CREATE INDEX IF NOT EXISTS IX_NewEvents_0056_ID_VisTime_Dequeue_WHERE_LockedBy_NULL ON NewEvents_0056(InstanceID, VisibleTime, DequeueCount) WHERE LockedBy IS NULL;
CREATE INDEX IF NOT EXISTS IX_NewEvents_0057_ID_VisTime_Dequeue_WHERE_LockedBy_NULL ON NewEvents_0057(InstanceID, VisibleTime, DequeueCount) WHERE LockedBy IS NULL;
CREATE INDEX IF NOT EXISTS IX_NewEvents_0058_ID_VisTime_Dequeue_WHERE_LockedBy_NULL ON NewEvents_0058(InstanceID, VisibleTime, DequeueCount) WHERE LockedBy IS NULL;
CREATE INDEX IF NOT EXISTS IX_NewEvents_0059_ID_VisTime_Dequeue_WHERE_LockedBy_NULL ON NewEvents_0059(InstanceID, VisibleTime, DequeueCount) WHERE LockedBy IS NULL;
CREATE INDEX IF NOT EXISTS IX_NewEvents_0060_ID_VisTime_Dequeue_WHERE_LockedBy_NULL ON NewEvents_0060(InstanceID, VisibleTime, DequeueCount) WHERE LockedBy IS NULL;
CREATE INDEX IF NOT EXISTS IX_NewEvents_0061_ID_VisTime_Dequeue_WHERE_LockedBy_NULL ON NewEvents_0061(InstanceID, VisibleTime, DequeueCount) WHERE LockedBy IS NULL;
CREATE INDEX IF NOT EXISTS IX_NewEvents_0062_ID_VisTime_Dequeue_WHERE_LockedBy_NULL ON NewEvents_0062(InstanceID, VisibleTime, DequeueCount) WHERE LockedBy IS NULL;
CREATE INDEX IF NOT EXISTS IX_NewEvents_0063_ID_VisTime_Dequeue_WHERE_LockedBy_NULL ON NewEvents_0063(InstanceID, VisibleTime, DequeueCount) WHERE LockedBy IS NULL;

-- Index for abandon operations (WHERE InstanceID = $1 AND LockedBy = $2)
CREATE INDEX IF NOT EXISTS IX_NewEvents_0000_InstanceID_LockedBy ON NewEvents_0000(InstanceID, LockedBy);
CREATE INDEX IF NOT EXISTS IX_NewEvents_0001_InstanceID_LockedBy ON NewEvents_0001(InstanceID, LockedBy);
CREATE INDEX IF NOT EXISTS IX_NewEvents_0002_InstanceID_LockedBy ON NewEvents_0002(InstanceID, LockedBy);
CREATE INDEX IF NOT EXISTS IX_NewEvents_0003_InstanceID_LockedBy ON NewEvents_0003(InstanceID, LockedBy);
CREATE INDEX IF NOT EXISTS IX_NewEvents_0004_InstanceID_LockedBy ON NewEvents_0004(InstanceID, LockedBy);
CREATE INDEX IF NOT EXISTS IX_NewEvents_0005_InstanceID_LockedBy ON NewEvents_0005(InstanceID, LockedBy);
CREATE INDEX IF NOT EXISTS IX_NewEvents_0006_InstanceID_LockedBy ON NewEvents_0006(InstanceID, LockedBy);
CREATE INDEX IF NOT EXISTS IX_NewEvents_0007_InstanceID_LockedBy ON NewEvents_0007(InstanceID, LockedBy);
CREATE INDEX IF NOT EXISTS IX_NewEvents_0008_InstanceID_LockedBy ON NewEvents_0008(InstanceID, LockedBy);
CREATE INDEX IF NOT EXISTS IX_NewEvents_0009_InstanceID_LockedBy ON NewEvents_0009(InstanceID, LockedBy);
CREATE INDEX IF NOT EXISTS IX_NewEvents_0010_InstanceID_LockedBy ON NewEvents_0010(InstanceID, LockedBy);
CREATE INDEX IF NOT EXISTS IX_NewEvents_0011_InstanceID_LockedBy ON NewEvents_0011(InstanceID, LockedBy);
CREATE INDEX IF NOT EXISTS IX_NewEvents_0012_InstanceID_LockedBy ON NewEvents_0012(InstanceID, LockedBy);
CREATE INDEX IF NOT EXISTS IX_NewEvents_0013_InstanceID_LockedBy ON NewEvents_0013(InstanceID, LockedBy);
CREATE INDEX IF NOT EXISTS IX_NewEvents_0014_InstanceID_LockedBy ON NewEvents_0014(InstanceID, LockedBy);
CREATE INDEX IF NOT EXISTS IX_NewEvents_0015_InstanceID_LockedBy ON NewEvents_0015(InstanceID, LockedBy);
CREATE INDEX IF NOT EXISTS IX_NewEvents_0016_InstanceID_LockedBy ON NewEvents_0016(InstanceID, LockedBy);
CREATE INDEX IF NOT EXISTS IX_NewEvents_0017_InstanceID_LockedBy ON NewEvents_0017(InstanceID, LockedBy);
CREATE INDEX IF NOT EXISTS IX_NewEvents_0018_InstanceID_LockedBy ON NewEvents_0018(InstanceID, LockedBy);
CREATE INDEX IF NOT EXISTS IX_NewEvents_0019_InstanceID_LockedBy ON NewEvents_0019(InstanceID, LockedBy);
CREATE INDEX IF NOT EXISTS IX_NewEvents_0020_InstanceID_LockedBy ON NewEvents_0020(InstanceID, LockedBy);
CREATE INDEX IF NOT EXISTS IX_NewEvents_0021_InstanceID_LockedBy ON NewEvents_0021(InstanceID, LockedBy);
CREATE INDEX IF NOT EXISTS IX_NewEvents_0022_InstanceID_LockedBy ON NewEvents_0022(InstanceID, LockedBy);
CREATE INDEX IF NOT EXISTS IX_NewEvents_0023_InstanceID_LockedBy ON NewEvents_0023(InstanceID, LockedBy);
CREATE INDEX IF NOT EXISTS IX_NewEvents_0024_InstanceID_LockedBy ON NewEvents_0024(InstanceID, LockedBy);
CREATE INDEX IF NOT EXISTS IX_NewEvents_0025_InstanceID_LockedBy ON NewEvents_0025(InstanceID, LockedBy);
CREATE INDEX IF NOT EXISTS IX_NewEvents_0026_InstanceID_LockedBy ON NewEvents_0026(InstanceID, LockedBy);
CREATE INDEX IF NOT EXISTS IX_NewEvents_0027_InstanceID_LockedBy ON NewEvents_0027(InstanceID, LockedBy);
CREATE INDEX IF NOT EXISTS IX_NewEvents_0028_InstanceID_LockedBy ON NewEvents_0028(InstanceID, LockedBy);
CREATE INDEX IF NOT EXISTS IX_NewEvents_0029_InstanceID_LockedBy ON NewEvents_0029(InstanceID, LockedBy);
CREATE INDEX IF NOT EXISTS IX_NewEvents_0030_InstanceID_LockedBy ON NewEvents_0030(InstanceID, LockedBy);
CREATE INDEX IF NOT EXISTS IX_NewEvents_0031_InstanceID_LockedBy ON NewEvents_0031(InstanceID, LockedBy);
CREATE INDEX IF NOT EXISTS IX_NewEvents_0032_InstanceID_LockedBy ON NewEvents_0032(InstanceID, LockedBy);
CREATE INDEX IF NOT EXISTS IX_NewEvents_0033_InstanceID_LockedBy ON NewEvents_0033(InstanceID, LockedBy);
CREATE INDEX IF NOT EXISTS IX_NewEvents_0034_InstanceID_LockedBy ON NewEvents_0034(InstanceID, LockedBy);
CREATE INDEX IF NOT EXISTS IX_NewEvents_0035_InstanceID_LockedBy ON NewEvents_0035(InstanceID, LockedBy);
CREATE INDEX IF NOT EXISTS IX_NewEvents_0036_InstanceID_LockedBy ON NewEvents_0036(InstanceID, LockedBy);
CREATE INDEX IF NOT EXISTS IX_NewEvents_0037_InstanceID_LockedBy ON NewEvents_0037(InstanceID, LockedBy);
CREATE INDEX IF NOT EXISTS IX_NewEvents_0038_InstanceID_LockedBy ON NewEvents_0038(InstanceID, LockedBy);
CREATE INDEX IF NOT EXISTS IX_NewEvents_0039_InstanceID_LockedBy ON NewEvents_0039(InstanceID, LockedBy);
CREATE INDEX IF NOT EXISTS IX_NewEvents_0040_InstanceID_LockedBy ON NewEvents_0040(InstanceID, LockedBy);
CREATE INDEX IF NOT EXISTS IX_NewEvents_0041_InstanceID_LockedBy ON NewEvents_0041(InstanceID, LockedBy);
CREATE INDEX IF NOT EXISTS IX_NewEvents_0042_InstanceID_LockedBy ON NewEvents_0042(InstanceID, LockedBy);
CREATE INDEX IF NOT EXISTS IX_NewEvents_0043_InstanceID_LockedBy ON NewEvents_0043(InstanceID, LockedBy);
CREATE INDEX IF NOT EXISTS IX_NewEvents_0044_InstanceID_LockedBy ON NewEvents_0044(InstanceID, LockedBy);
CREATE INDEX IF NOT EXISTS IX_NewEvents_0045_InstanceID_LockedBy ON NewEvents_0045(InstanceID, LockedBy);
CREATE INDEX IF NOT EXISTS IX_NewEvents_0046_InstanceID_LockedBy ON NewEvents_0046(InstanceID, LockedBy);
CREATE INDEX IF NOT EXISTS IX_NewEvents_0047_InstanceID_LockedBy ON NewEvents_0047(InstanceID, LockedBy);
CREATE INDEX IF NOT EXISTS IX_NewEvents_0048_InstanceID_LockedBy ON NewEvents_0048(InstanceID, LockedBy);
CREATE INDEX IF NOT EXISTS IX_NewEvents_0049_InstanceID_LockedBy ON NewEvents_0049(InstanceID, LockedBy);
CREATE INDEX IF NOT EXISTS IX_NewEvents_0050_InstanceID_LockedBy ON NewEvents_0050(InstanceID, LockedBy);
CREATE INDEX IF NOT EXISTS IX_NewEvents_0051_InstanceID_LockedBy ON NewEvents_0051(InstanceID, LockedBy);
CREATE INDEX IF NOT EXISTS IX_NewEvents_0052_InstanceID_LockedBy ON NewEvents_0052(InstanceID, LockedBy);
CREATE INDEX IF NOT EXISTS IX_NewEvents_0053_InstanceID_LockedBy ON NewEvents_0053(InstanceID, LockedBy);
CREATE INDEX IF NOT EXISTS IX_NewEvents_0054_InstanceID_LockedBy ON NewEvents_0054(InstanceID, LockedBy);
CREATE INDEX IF NOT EXISTS IX_NewEvents_0055_InstanceID_LockedBy ON NewEvents_0055(InstanceID, LockedBy);
CREATE INDEX IF NOT EXISTS IX_NewEvents_0056_InstanceID_LockedBy ON NewEvents_0056(InstanceID, LockedBy);
CREATE INDEX IF NOT EXISTS IX_NewEvents_0057_InstanceID_LockedBy ON NewEvents_0057(InstanceID, LockedBy);
CREATE INDEX IF NOT EXISTS IX_NewEvents_0058_InstanceID_LockedBy ON NewEvents_0058(InstanceID, LockedBy);
CREATE INDEX IF NOT EXISTS IX_NewEvents_0059_InstanceID_LockedBy ON NewEvents_0059(InstanceID, LockedBy);
CREATE INDEX IF NOT EXISTS IX_NewEvents_0060_InstanceID_LockedBy ON NewEvents_0060(InstanceID, LockedBy);
CREATE INDEX IF NOT EXISTS IX_NewEvents_0061_InstanceID_LockedBy ON NewEvents_0061(InstanceID, LockedBy);
CREATE INDEX IF NOT EXISTS IX_NewEvents_0062_InstanceID_LockedBy ON NewEvents_0062(InstanceID, LockedBy);
CREATE INDEX IF NOT EXISTS IX_NewEvents_0063_InstanceID_LockedBy ON NewEvents_0063(InstanceID, LockedBy);

-- Full index for ORDER BY InstanceID, SequenceNumber (supports all rows)
CREATE INDEX IF NOT EXISTS IX_NewEvents_0000_InstanceID_SequenceNumber ON NewEvents_0000(InstanceID, SequenceNumber);
CREATE INDEX IF NOT EXISTS IX_NewEvents_0001_InstanceID_SequenceNumber ON NewEvents_0001(InstanceID, SequenceNumber);
CREATE INDEX IF NOT EXISTS IX_NewEvents_0002_InstanceID_SequenceNumber ON NewEvents_0002(InstanceID, SequenceNumber);
CREATE INDEX IF NOT EXISTS IX_NewEvents_0003_InstanceID_SequenceNumber ON NewEvents_0003(InstanceID, SequenceNumber);
CREATE INDEX IF NOT EXISTS IX_NewEvents_0004_InstanceID_SequenceNumber ON NewEvents_0004(InstanceID, SequenceNumber);
CREATE INDEX IF NOT EXISTS IX_NewEvents_0005_InstanceID_SequenceNumber ON NewEvents_0005(InstanceID, SequenceNumber);
CREATE INDEX IF NOT EXISTS IX_NewEvents_0006_InstanceID_SequenceNumber ON NewEvents_0006(InstanceID, SequenceNumber);
CREATE INDEX IF NOT EXISTS IX_NewEvents_0007_InstanceID_SequenceNumber ON NewEvents_0007(InstanceID, SequenceNumber);
CREATE INDEX IF NOT EXISTS IX_NewEvents_0008_InstanceID_SequenceNumber ON NewEvents_0008(InstanceID, SequenceNumber);
CREATE INDEX IF NOT EXISTS IX_NewEvents_0009_InstanceID_SequenceNumber ON NewEvents_0009(InstanceID, SequenceNumber);
CREATE INDEX IF NOT EXISTS IX_NewEvents_0010_InstanceID_SequenceNumber ON NewEvents_0010(InstanceID, SequenceNumber);
CREATE INDEX IF NOT EXISTS IX_NewEvents_0011_InstanceID_SequenceNumber ON NewEvents_0011(InstanceID, SequenceNumber);
CREATE INDEX IF NOT EXISTS IX_NewEvents_0012_InstanceID_SequenceNumber ON NewEvents_0012(InstanceID, SequenceNumber);
CREATE INDEX IF NOT EXISTS IX_NewEvents_0013_InstanceID_SequenceNumber ON NewEvents_0013(InstanceID, SequenceNumber);
CREATE INDEX IF NOT EXISTS IX_NewEvents_0014_InstanceID_SequenceNumber ON NewEvents_0014(InstanceID, SequenceNumber);
CREATE INDEX IF NOT EXISTS IX_NewEvents_0015_InstanceID_SequenceNumber ON NewEvents_0015(InstanceID, SequenceNumber);
CREATE INDEX IF NOT EXISTS IX_NewEvents_0016_InstanceID_SequenceNumber ON NewEvents_0016(InstanceID, SequenceNumber);
CREATE INDEX IF NOT EXISTS IX_NewEvents_0017_InstanceID_SequenceNumber ON NewEvents_0017(InstanceID, SequenceNumber);
CREATE INDEX IF NOT EXISTS IX_NewEvents_0018_InstanceID_SequenceNumber ON NewEvents_0018(InstanceID, SequenceNumber);
CREATE INDEX IF NOT EXISTS IX_NewEvents_0019_InstanceID_SequenceNumber ON NewEvents_0019(InstanceID, SequenceNumber);
CREATE INDEX IF NOT EXISTS IX_NewEvents_0020_InstanceID_SequenceNumber ON NewEvents_0020(InstanceID, SequenceNumber);
CREATE INDEX IF NOT EXISTS IX_NewEvents_0021_InstanceID_SequenceNumber ON NewEvents_0021(InstanceID, SequenceNumber);
CREATE INDEX IF NOT EXISTS IX_NewEvents_0022_InstanceID_SequenceNumber ON NewEvents_0022(InstanceID, SequenceNumber);
CREATE INDEX IF NOT EXISTS IX_NewEvents_0023_InstanceID_SequenceNumber ON NewEvents_0023(InstanceID, SequenceNumber);
CREATE INDEX IF NOT EXISTS IX_NewEvents_0024_InstanceID_SequenceNumber ON NewEvents_0024(InstanceID, SequenceNumber);
CREATE INDEX IF NOT EXISTS IX_NewEvents_0025_InstanceID_SequenceNumber ON NewEvents_0025(InstanceID, SequenceNumber);
CREATE INDEX IF NOT EXISTS IX_NewEvents_0026_InstanceID_SequenceNumber ON NewEvents_0026(InstanceID, SequenceNumber);
CREATE INDEX IF NOT EXISTS IX_NewEvents_0027_InstanceID_SequenceNumber ON NewEvents_0027(InstanceID, SequenceNumber);
CREATE INDEX IF NOT EXISTS IX_NewEvents_0028_InstanceID_SequenceNumber ON NewEvents_0028(InstanceID, SequenceNumber);
CREATE INDEX IF NOT EXISTS IX_NewEvents_0029_InstanceID_SequenceNumber ON NewEvents_0029(InstanceID, SequenceNumber);
CREATE INDEX IF NOT EXISTS IX_NewEvents_0030_InstanceID_SequenceNumber ON NewEvents_0030(InstanceID, SequenceNumber);
CREATE INDEX IF NOT EXISTS IX_NewEvents_0031_InstanceID_SequenceNumber ON NewEvents_0031(InstanceID, SequenceNumber);
CREATE INDEX IF NOT EXISTS IX_NewEvents_0032_InstanceID_SequenceNumber ON NewEvents_0032(InstanceID, SequenceNumber);
CREATE INDEX IF NOT EXISTS IX_NewEvents_0033_InstanceID_SequenceNumber ON NewEvents_0033(InstanceID, SequenceNumber);
CREATE INDEX IF NOT EXISTS IX_NewEvents_0034_InstanceID_SequenceNumber ON NewEvents_0034(InstanceID, SequenceNumber);
CREATE INDEX IF NOT EXISTS IX_NewEvents_0035_InstanceID_SequenceNumber ON NewEvents_0035(InstanceID, SequenceNumber);
CREATE INDEX IF NOT EXISTS IX_NewEvents_0036_InstanceID_SequenceNumber ON NewEvents_0036(InstanceID, SequenceNumber);
CREATE INDEX IF NOT EXISTS IX_NewEvents_0037_InstanceID_SequenceNumber ON NewEvents_0037(InstanceID, SequenceNumber);
CREATE INDEX IF NOT EXISTS IX_NewEvents_0038_InstanceID_SequenceNumber ON NewEvents_0038(InstanceID, SequenceNumber);
CREATE INDEX IF NOT EXISTS IX_NewEvents_0039_InstanceID_SequenceNumber ON NewEvents_0039(InstanceID, SequenceNumber);
CREATE INDEX IF NOT EXISTS IX_NewEvents_0040_InstanceID_SequenceNumber ON NewEvents_0040(InstanceID, SequenceNumber);
CREATE INDEX IF NOT EXISTS IX_NewEvents_0041_InstanceID_SequenceNumber ON NewEvents_0041(InstanceID, SequenceNumber);
CREATE INDEX IF NOT EXISTS IX_NewEvents_0042_InstanceID_SequenceNumber ON NewEvents_0042(InstanceID, SequenceNumber);
CREATE INDEX IF NOT EXISTS IX_NewEvents_0043_InstanceID_SequenceNumber ON NewEvents_0043(InstanceID, SequenceNumber);
CREATE INDEX IF NOT EXISTS IX_NewEvents_0044_InstanceID_SequenceNumber ON NewEvents_0044(InstanceID, SequenceNumber);
CREATE INDEX IF NOT EXISTS IX_NewEvents_0045_InstanceID_SequenceNumber ON NewEvents_0045(InstanceID, SequenceNumber);
CREATE INDEX IF NOT EXISTS IX_NewEvents_0046_InstanceID_SequenceNumber ON NewEvents_0046(InstanceID, SequenceNumber);
CREATE INDEX IF NOT EXISTS IX_NewEvents_0047_InstanceID_SequenceNumber ON NewEvents_0047(InstanceID, SequenceNumber);
CREATE INDEX IF NOT EXISTS IX_NewEvents_0048_InstanceID_SequenceNumber ON NewEvents_0048(InstanceID, SequenceNumber);
CREATE INDEX IF NOT EXISTS IX_NewEvents_0049_InstanceID_SequenceNumber ON NewEvents_0049(InstanceID, SequenceNumber);
CREATE INDEX IF NOT EXISTS IX_NewEvents_0050_InstanceID_SequenceNumber ON NewEvents_0050(InstanceID, SequenceNumber);
CREATE INDEX IF NOT EXISTS IX_NewEvents_0051_InstanceID_SequenceNumber ON NewEvents_0051(InstanceID, SequenceNumber);
CREATE INDEX IF NOT EXISTS IX_NewEvents_0052_InstanceID_SequenceNumber ON NewEvents_0052(InstanceID, SequenceNumber);
CREATE INDEX IF NOT EXISTS IX_NewEvents_0053_InstanceID_SequenceNumber ON NewEvents_0053(InstanceID, SequenceNumber);
CREATE INDEX IF NOT EXISTS IX_NewEvents_0054_InstanceID_SequenceNumber ON NewEvents_0054(InstanceID, SequenceNumber);
CREATE INDEX IF NOT EXISTS IX_NewEvents_0055_InstanceID_SequenceNumber ON NewEvents_0055(InstanceID, SequenceNumber);
CREATE INDEX IF NOT EXISTS IX_NewEvents_0056_InstanceID_SequenceNumber ON NewEvents_0056(InstanceID, SequenceNumber);
CREATE INDEX IF NOT EXISTS IX_NewEvents_0057_InstanceID_SequenceNumber ON NewEvents_0057(InstanceID, SequenceNumber);
CREATE INDEX IF NOT EXISTS IX_NewEvents_0058_InstanceID_SequenceNumber ON NewEvents_0058(InstanceID, SequenceNumber);
CREATE INDEX IF NOT EXISTS IX_NewEvents_0059_InstanceID_SequenceNumber ON NewEvents_0059(InstanceID, SequenceNumber);
CREATE INDEX IF NOT EXISTS IX_NewEvents_0060_InstanceID_SequenceNumber ON NewEvents_0060(InstanceID, SequenceNumber);
CREATE INDEX IF NOT EXISTS IX_NewEvents_0061_InstanceID_SequenceNumber ON NewEvents_0061(InstanceID, SequenceNumber);
CREATE INDEX IF NOT EXISTS IX_NewEvents_0062_InstanceID_SequenceNumber ON NewEvents_0062(InstanceID, SequenceNumber);
CREATE INDEX IF NOT EXISTS IX_NewEvents_0063_InstanceID_SequenceNumber ON NewEvents_0063(InstanceID, SequenceNumber);

-- ============================================================================
-- NewTasks Table (single table, no partitioning)
-- ============================================================================
-- NOTE: Unlike NewEvents/History, NewTasks is intentionally NOT hash-partitioned by
-- InstanceID. Its hottest query patterns (poll, complete, abandon) do not filter by
-- InstanceID at all, so hash partitioning on InstanceID cannot prune and instead forces
-- every poll/complete/abandon call to fan out across all partitions. Only INSERT and the
-- per-instance purge DELETE benefit from InstanceID-based partitioning, so a single table
-- with targeted indexes performs better overall.
CREATE TABLE IF NOT EXISTS NewTasks (
    SequenceNumber BIGSERIAL PRIMARY KEY,
    InstanceID TEXT NOT NULL,
    ExecutionID TEXT NULL,
    Timestamp TIMESTAMP NOT NULL DEFAULT NOW(),
    DequeueCount INTEGER NOT NULL DEFAULT 0,
    LockedBy TEXT NULL,
    LockExpiration TIMESTAMP NULL,
    EventPayload BYTEA NOT NULL
);

ALTER TABLE NewTasks SET (fillfactor = 70);
ALTER TABLE NewTasks SET (autovacuum_vacuum_scale_factor = 0.05, autovacuum_vacuum_threshold = 5000, autovacuum_analyze_scale_factor = 0.05, autovacuum_analyze_threshold = 2000);

-- Poll query coverage: WHERE (LockExpiration IS NULL OR LockExpiration < $3) ORDER BY InstanceID, SequenceNumber
CREATE INDEX IF NOT EXISTS IX_NewTasks_LockExp_Null_ID_SeqNum ON NewTasks(LockExpiration, InstanceID, SequenceNumber)
WHERE LockExpiration IS NULL;

CREATE INDEX IF NOT EXISTS IX_NewTasks_LockExp_NotNull_ID_SeqNum ON NewTasks(LockExpiration, InstanceID, SequenceNumber)
WHERE LockExpiration IS NOT NULL;

-- Cleanup path: WHERE InstanceID = $1
CREATE INDEX IF NOT EXISTS IX_NewTasks_InstanceID ON NewTasks(InstanceID);


-- ============================================================================
-- Summary of Performance Improvements
-- ============================================================================
-- 1. BIGSERIAL instead of SERIAL - Prevents sequence exhaustion at high scale
-- 2. Hash partitioning for NewEvents and NewTasks - Better parallelism and reduced contention
-- 3. Partial indexes - 80-90% size reduction for active rows only
-- 4. Fillfactor settings - Reduces page splits for HOT updates (applied to partitions)
-- 5. Autovacuum tuning - Aggressive cleanup for high-churn tables (applied to partitions)
-- 6. Composite indexes - Optimized for complex locking query patterns
-- ============================================================================
