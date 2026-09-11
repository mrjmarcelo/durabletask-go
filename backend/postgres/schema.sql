-- ============================================================================
-- Enhanced Schema for Durable Task Backend (v2)
-- ============================================================================

-- ============================================================================
-- Instances Table (with partitioning and performance optimizations)
-- ============================================================================
CREATE TABLE IF NOT EXISTS Instances (
    SequenceNumber BIGSERIAL,  -- Changed to BIGSERIAL for high scale
    InstanceID TEXT NOT NULL,
    ExecutionID TEXT NOT NULL,
    Name TEXT NOT NULL, -- the type name of the orchestration or entity
    Version TEXT NULL, -- the version of the orchestration (optional)
    RuntimeStatus TEXT NOT NULL,
    CreatedTime TIMESTAMP NOT NULL DEFAULT NOW(),
    LastUpdatedTime TIMESTAMP NOT NULL DEFAULT NOW(),
    CompletedTime TIMESTAMP NULL,
    DequeueCount INTEGER NOT NULL DEFAULT 0,
    LockedBy TEXT NULL,
    LockExpiration TIMESTAMP NULL DEFAULT '-infinity', -- a timestamp  -> lease held until that time. '-infinity'  -> no lease held, eligible for immediate dequeue. NULL -> reached a terminal status, never dequeue again
    Input TEXT NULL,
    Output TEXT NULL,
    CustomStatus TEXT NULL,
    FailureDetails BYTEA NULL,
    ParentInstanceID TEXT NULL,
    PRIMARY KEY (InstanceID)
) PARTITION BY HASH (InstanceID);

-- Create 128 partitions matching NewEvents for consistency
CREATE TABLE IF NOT EXISTS Instances_0000 PARTITION OF Instances FOR VALUES WITH (MODULUS 128, REMAINDER 0);
ALTER TABLE Instances_0000 SET (fillfactor = 70);
ALTER TABLE Instances_0000 SET (autovacuum_vacuum_scale_factor = 0.05, autovacuum_vacuum_threshold = 5000, autovacuum_analyze_scale_factor = 0.05, autovacuum_analyze_threshold = 2000);

CREATE TABLE IF NOT EXISTS Instances_0001 PARTITION OF Instances FOR VALUES WITH (MODULUS 128, REMAINDER 1);
ALTER TABLE Instances_0001 SET (fillfactor = 70);
ALTER TABLE Instances_0001 SET (autovacuum_vacuum_scale_factor = 0.05, autovacuum_vacuum_threshold = 5000, autovacuum_analyze_scale_factor = 0.05, autovacuum_analyze_threshold = 2000);

CREATE TABLE IF NOT EXISTS Instances_0002 PARTITION OF Instances FOR VALUES WITH (MODULUS 128, REMAINDER 2);
ALTER TABLE Instances_0002 SET (fillfactor = 70);
ALTER TABLE Instances_0002 SET (autovacuum_vacuum_scale_factor = 0.05, autovacuum_vacuum_threshold = 5000, autovacuum_analyze_scale_factor = 0.05, autovacuum_analyze_threshold = 2000);

CREATE TABLE IF NOT EXISTS Instances_0003 PARTITION OF Instances FOR VALUES WITH (MODULUS 128, REMAINDER 3);
ALTER TABLE Instances_0003 SET (fillfactor = 70);
ALTER TABLE Instances_0003 SET (autovacuum_vacuum_scale_factor = 0.05, autovacuum_vacuum_threshold = 5000, autovacuum_analyze_scale_factor = 0.05, autovacuum_analyze_threshold = 2000);

CREATE TABLE IF NOT EXISTS Instances_0004 PARTITION OF Instances FOR VALUES WITH (MODULUS 128, REMAINDER 4);
ALTER TABLE Instances_0004 SET (fillfactor = 70);
ALTER TABLE Instances_0004 SET (autovacuum_vacuum_scale_factor = 0.05, autovacuum_vacuum_threshold = 5000, autovacuum_analyze_scale_factor = 0.05, autovacuum_analyze_threshold = 2000);

CREATE TABLE IF NOT EXISTS Instances_0005 PARTITION OF Instances FOR VALUES WITH (MODULUS 128, REMAINDER 5);
ALTER TABLE Instances_0005 SET (fillfactor = 70);
ALTER TABLE Instances_0005 SET (autovacuum_vacuum_scale_factor = 0.05, autovacuum_vacuum_threshold = 5000, autovacuum_analyze_scale_factor = 0.05, autovacuum_analyze_threshold = 2000);

CREATE TABLE IF NOT EXISTS Instances_0006 PARTITION OF Instances FOR VALUES WITH (MODULUS 128, REMAINDER 6);
ALTER TABLE Instances_0006 SET (fillfactor = 70);
ALTER TABLE Instances_0006 SET (autovacuum_vacuum_scale_factor = 0.05, autovacuum_vacuum_threshold = 5000, autovacuum_analyze_scale_factor = 0.05, autovacuum_analyze_threshold = 2000);

CREATE TABLE IF NOT EXISTS Instances_0007 PARTITION OF Instances FOR VALUES WITH (MODULUS 128, REMAINDER 7);
ALTER TABLE Instances_0007 SET (fillfactor = 70);
ALTER TABLE Instances_0007 SET (autovacuum_vacuum_scale_factor = 0.05, autovacuum_vacuum_threshold = 5000, autovacuum_analyze_scale_factor = 0.05, autovacuum_analyze_threshold = 2000);

CREATE TABLE IF NOT EXISTS Instances_0008 PARTITION OF Instances FOR VALUES WITH (MODULUS 128, REMAINDER 8);
ALTER TABLE Instances_0008 SET (fillfactor = 70);
ALTER TABLE Instances_0008 SET (autovacuum_vacuum_scale_factor = 0.05, autovacuum_vacuum_threshold = 5000, autovacuum_analyze_scale_factor = 0.05, autovacuum_analyze_threshold = 2000);

CREATE TABLE IF NOT EXISTS Instances_0009 PARTITION OF Instances FOR VALUES WITH (MODULUS 128, REMAINDER 9);
ALTER TABLE Instances_0009 SET (fillfactor = 70);
ALTER TABLE Instances_0009 SET (autovacuum_vacuum_scale_factor = 0.05, autovacuum_vacuum_threshold = 5000, autovacuum_analyze_scale_factor = 0.05, autovacuum_analyze_threshold = 2000);

CREATE TABLE IF NOT EXISTS Instances_0010 PARTITION OF Instances FOR VALUES WITH (MODULUS 128, REMAINDER 10);
ALTER TABLE Instances_0010 SET (fillfactor = 70);
ALTER TABLE Instances_0010 SET (autovacuum_vacuum_scale_factor = 0.05, autovacuum_vacuum_threshold = 5000, autovacuum_analyze_scale_factor = 0.05, autovacuum_analyze_threshold = 2000);

CREATE TABLE IF NOT EXISTS Instances_0011 PARTITION OF Instances FOR VALUES WITH (MODULUS 128, REMAINDER 11);
ALTER TABLE Instances_0011 SET (fillfactor = 70);
ALTER TABLE Instances_0011 SET (autovacuum_vacuum_scale_factor = 0.05, autovacuum_vacuum_threshold = 5000, autovacuum_analyze_scale_factor = 0.05, autovacuum_analyze_threshold = 2000);

CREATE TABLE IF NOT EXISTS Instances_0012 PARTITION OF Instances FOR VALUES WITH (MODULUS 128, REMAINDER 12);
ALTER TABLE Instances_0012 SET (fillfactor = 70);
ALTER TABLE Instances_0012 SET (autovacuum_vacuum_scale_factor = 0.05, autovacuum_vacuum_threshold = 5000, autovacuum_analyze_scale_factor = 0.05, autovacuum_analyze_threshold = 2000);

CREATE TABLE IF NOT EXISTS Instances_0013 PARTITION OF Instances FOR VALUES WITH (MODULUS 128, REMAINDER 13);
ALTER TABLE Instances_0013 SET (fillfactor = 70);
ALTER TABLE Instances_0013 SET (autovacuum_vacuum_scale_factor = 0.05, autovacuum_vacuum_threshold = 5000, autovacuum_analyze_scale_factor = 0.05, autovacuum_analyze_threshold = 2000);

CREATE TABLE IF NOT EXISTS Instances_0014 PARTITION OF Instances FOR VALUES WITH (MODULUS 128, REMAINDER 14);
ALTER TABLE Instances_0014 SET (fillfactor = 70);
ALTER TABLE Instances_0014 SET (autovacuum_vacuum_scale_factor = 0.05, autovacuum_vacuum_threshold = 5000, autovacuum_analyze_scale_factor = 0.05, autovacuum_analyze_threshold = 2000);

CREATE TABLE IF NOT EXISTS Instances_0015 PARTITION OF Instances FOR VALUES WITH (MODULUS 128, REMAINDER 15);
ALTER TABLE Instances_0015 SET (fillfactor = 70);
ALTER TABLE Instances_0015 SET (autovacuum_vacuum_scale_factor = 0.05, autovacuum_vacuum_threshold = 5000, autovacuum_analyze_scale_factor = 0.05, autovacuum_analyze_threshold = 2000);

CREATE TABLE IF NOT EXISTS Instances_0016 PARTITION OF Instances FOR VALUES WITH (MODULUS 128, REMAINDER 16);
ALTER TABLE Instances_0016 SET (fillfactor = 70);
ALTER TABLE Instances_0016 SET (autovacuum_vacuum_scale_factor = 0.05, autovacuum_vacuum_threshold = 5000, autovacuum_analyze_scale_factor = 0.05, autovacuum_analyze_threshold = 2000);

CREATE TABLE IF NOT EXISTS Instances_0017 PARTITION OF Instances FOR VALUES WITH (MODULUS 128, REMAINDER 17);
ALTER TABLE Instances_0017 SET (fillfactor = 70);
ALTER TABLE Instances_0017 SET (autovacuum_vacuum_scale_factor = 0.05, autovacuum_vacuum_threshold = 5000, autovacuum_analyze_scale_factor = 0.05, autovacuum_analyze_threshold = 2000);

CREATE TABLE IF NOT EXISTS Instances_0018 PARTITION OF Instances FOR VALUES WITH (MODULUS 128, REMAINDER 18);
ALTER TABLE Instances_0018 SET (fillfactor = 70);
ALTER TABLE Instances_0018 SET (autovacuum_vacuum_scale_factor = 0.05, autovacuum_vacuum_threshold = 5000, autovacuum_analyze_scale_factor = 0.05, autovacuum_analyze_threshold = 2000);

CREATE TABLE IF NOT EXISTS Instances_0019 PARTITION OF Instances FOR VALUES WITH (MODULUS 128, REMAINDER 19);
ALTER TABLE Instances_0019 SET (fillfactor = 70);
ALTER TABLE Instances_0019 SET (autovacuum_vacuum_scale_factor = 0.05, autovacuum_vacuum_threshold = 5000, autovacuum_analyze_scale_factor = 0.05, autovacuum_analyze_threshold = 2000);

CREATE TABLE IF NOT EXISTS Instances_0020 PARTITION OF Instances FOR VALUES WITH (MODULUS 128, REMAINDER 20);
ALTER TABLE Instances_0020 SET (fillfactor = 70);
ALTER TABLE Instances_0020 SET (autovacuum_vacuum_scale_factor = 0.05, autovacuum_vacuum_threshold = 5000, autovacuum_analyze_scale_factor = 0.05, autovacuum_analyze_threshold = 2000);

CREATE TABLE IF NOT EXISTS Instances_0021 PARTITION OF Instances FOR VALUES WITH (MODULUS 128, REMAINDER 21);
ALTER TABLE Instances_0021 SET (fillfactor = 70);
ALTER TABLE Instances_0021 SET (autovacuum_vacuum_scale_factor = 0.05, autovacuum_vacuum_threshold = 5000, autovacuum_analyze_scale_factor = 0.05, autovacuum_analyze_threshold = 2000);

CREATE TABLE IF NOT EXISTS Instances_0022 PARTITION OF Instances FOR VALUES WITH (MODULUS 128, REMAINDER 22);
ALTER TABLE Instances_0022 SET (fillfactor = 70);
ALTER TABLE Instances_0022 SET (autovacuum_vacuum_scale_factor = 0.05, autovacuum_vacuum_threshold = 5000, autovacuum_analyze_scale_factor = 0.05, autovacuum_analyze_threshold = 2000);

CREATE TABLE IF NOT EXISTS Instances_0023 PARTITION OF Instances FOR VALUES WITH (MODULUS 128, REMAINDER 23);
ALTER TABLE Instances_0023 SET (fillfactor = 70);
ALTER TABLE Instances_0023 SET (autovacuum_vacuum_scale_factor = 0.05, autovacuum_vacuum_threshold = 5000, autovacuum_analyze_scale_factor = 0.05, autovacuum_analyze_threshold = 2000);

CREATE TABLE IF NOT EXISTS Instances_0024 PARTITION OF Instances FOR VALUES WITH (MODULUS 128, REMAINDER 24);
ALTER TABLE Instances_0024 SET (fillfactor = 70);
ALTER TABLE Instances_0024 SET (autovacuum_vacuum_scale_factor = 0.05, autovacuum_vacuum_threshold = 5000, autovacuum_analyze_scale_factor = 0.05, autovacuum_analyze_threshold = 2000);

CREATE TABLE IF NOT EXISTS Instances_0025 PARTITION OF Instances FOR VALUES WITH (MODULUS 128, REMAINDER 25);
ALTER TABLE Instances_0025 SET (fillfactor = 70);
ALTER TABLE Instances_0025 SET (autovacuum_vacuum_scale_factor = 0.05, autovacuum_vacuum_threshold = 5000, autovacuum_analyze_scale_factor = 0.05, autovacuum_analyze_threshold = 2000);

CREATE TABLE IF NOT EXISTS Instances_0026 PARTITION OF Instances FOR VALUES WITH (MODULUS 128, REMAINDER 26);
ALTER TABLE Instances_0026 SET (fillfactor = 70);
ALTER TABLE Instances_0026 SET (autovacuum_vacuum_scale_factor = 0.05, autovacuum_vacuum_threshold = 5000, autovacuum_analyze_scale_factor = 0.05, autovacuum_analyze_threshold = 2000);

CREATE TABLE IF NOT EXISTS Instances_0027 PARTITION OF Instances FOR VALUES WITH (MODULUS 128, REMAINDER 27);
ALTER TABLE Instances_0027 SET (fillfactor = 70);
ALTER TABLE Instances_0027 SET (autovacuum_vacuum_scale_factor = 0.05, autovacuum_vacuum_threshold = 5000, autovacuum_analyze_scale_factor = 0.05, autovacuum_analyze_threshold = 2000);

CREATE TABLE IF NOT EXISTS Instances_0028 PARTITION OF Instances FOR VALUES WITH (MODULUS 128, REMAINDER 28);
ALTER TABLE Instances_0028 SET (fillfactor = 70);
ALTER TABLE Instances_0028 SET (autovacuum_vacuum_scale_factor = 0.05, autovacuum_vacuum_threshold = 5000, autovacuum_analyze_scale_factor = 0.05, autovacuum_analyze_threshold = 2000);

CREATE TABLE IF NOT EXISTS Instances_0029 PARTITION OF Instances FOR VALUES WITH (MODULUS 128, REMAINDER 29);
ALTER TABLE Instances_0029 SET (fillfactor = 70);
ALTER TABLE Instances_0029 SET (autovacuum_vacuum_scale_factor = 0.05, autovacuum_vacuum_threshold = 5000, autovacuum_analyze_scale_factor = 0.05, autovacuum_analyze_threshold = 2000);

CREATE TABLE IF NOT EXISTS Instances_0030 PARTITION OF Instances FOR VALUES WITH (MODULUS 128, REMAINDER 30);
ALTER TABLE Instances_0030 SET (fillfactor = 70);
ALTER TABLE Instances_0030 SET (autovacuum_vacuum_scale_factor = 0.05, autovacuum_vacuum_threshold = 5000, autovacuum_analyze_scale_factor = 0.05, autovacuum_analyze_threshold = 2000);

CREATE TABLE IF NOT EXISTS Instances_0031 PARTITION OF Instances FOR VALUES WITH (MODULUS 128, REMAINDER 31);
ALTER TABLE Instances_0031 SET (fillfactor = 70);
ALTER TABLE Instances_0031 SET (autovacuum_vacuum_scale_factor = 0.05, autovacuum_vacuum_threshold = 5000, autovacuum_analyze_scale_factor = 0.05, autovacuum_analyze_threshold = 2000);

CREATE TABLE IF NOT EXISTS Instances_0032 PARTITION OF Instances FOR VALUES WITH (MODULUS 128, REMAINDER 32);
ALTER TABLE Instances_0032 SET (fillfactor = 70);
ALTER TABLE Instances_0032 SET (autovacuum_vacuum_scale_factor = 0.05, autovacuum_vacuum_threshold = 5000, autovacuum_analyze_scale_factor = 0.05, autovacuum_analyze_threshold = 2000);

CREATE TABLE IF NOT EXISTS Instances_0033 PARTITION OF Instances FOR VALUES WITH (MODULUS 128, REMAINDER 33);
ALTER TABLE Instances_0033 SET (fillfactor = 70);
ALTER TABLE Instances_0033 SET (autovacuum_vacuum_scale_factor = 0.05, autovacuum_vacuum_threshold = 5000, autovacuum_analyze_scale_factor = 0.05, autovacuum_analyze_threshold = 2000);

CREATE TABLE IF NOT EXISTS Instances_0034 PARTITION OF Instances FOR VALUES WITH (MODULUS 128, REMAINDER 34);
ALTER TABLE Instances_0034 SET (fillfactor = 70);
ALTER TABLE Instances_0034 SET (autovacuum_vacuum_scale_factor = 0.05, autovacuum_vacuum_threshold = 5000, autovacuum_analyze_scale_factor = 0.05, autovacuum_analyze_threshold = 2000);

CREATE TABLE IF NOT EXISTS Instances_0035 PARTITION OF Instances FOR VALUES WITH (MODULUS 128, REMAINDER 35);
ALTER TABLE Instances_0035 SET (fillfactor = 70);
ALTER TABLE Instances_0035 SET (autovacuum_vacuum_scale_factor = 0.05, autovacuum_vacuum_threshold = 5000, autovacuum_analyze_scale_factor = 0.05, autovacuum_analyze_threshold = 2000);

CREATE TABLE IF NOT EXISTS Instances_0036 PARTITION OF Instances FOR VALUES WITH (MODULUS 128, REMAINDER 36);
ALTER TABLE Instances_0036 SET (fillfactor = 70);
ALTER TABLE Instances_0036 SET (autovacuum_vacuum_scale_factor = 0.05, autovacuum_vacuum_threshold = 5000, autovacuum_analyze_scale_factor = 0.05, autovacuum_analyze_threshold = 2000);

CREATE TABLE IF NOT EXISTS Instances_0037 PARTITION OF Instances FOR VALUES WITH (MODULUS 128, REMAINDER 37);
ALTER TABLE Instances_0037 SET (fillfactor = 70);
ALTER TABLE Instances_0037 SET (autovacuum_vacuum_scale_factor = 0.05, autovacuum_vacuum_threshold = 5000, autovacuum_analyze_scale_factor = 0.05, autovacuum_analyze_threshold = 2000);

CREATE TABLE IF NOT EXISTS Instances_0038 PARTITION OF Instances FOR VALUES WITH (MODULUS 128, REMAINDER 38);
ALTER TABLE Instances_0038 SET (fillfactor = 70);
ALTER TABLE Instances_0038 SET (autovacuum_vacuum_scale_factor = 0.05, autovacuum_vacuum_threshold = 5000, autovacuum_analyze_scale_factor = 0.05, autovacuum_analyze_threshold = 2000);

CREATE TABLE IF NOT EXISTS Instances_0039 PARTITION OF Instances FOR VALUES WITH (MODULUS 128, REMAINDER 39);
ALTER TABLE Instances_0039 SET (fillfactor = 70);
ALTER TABLE Instances_0039 SET (autovacuum_vacuum_scale_factor = 0.05, autovacuum_vacuum_threshold = 5000, autovacuum_analyze_scale_factor = 0.05, autovacuum_analyze_threshold = 2000);

CREATE TABLE IF NOT EXISTS Instances_0040 PARTITION OF Instances FOR VALUES WITH (MODULUS 128, REMAINDER 40);
ALTER TABLE Instances_0040 SET (fillfactor = 70);
ALTER TABLE Instances_0040 SET (autovacuum_vacuum_scale_factor = 0.05, autovacuum_vacuum_threshold = 5000, autovacuum_analyze_scale_factor = 0.05, autovacuum_analyze_threshold = 2000);

CREATE TABLE IF NOT EXISTS Instances_0041 PARTITION OF Instances FOR VALUES WITH (MODULUS 128, REMAINDER 41);
ALTER TABLE Instances_0041 SET (fillfactor = 70);
ALTER TABLE Instances_0041 SET (autovacuum_vacuum_scale_factor = 0.05, autovacuum_vacuum_threshold = 5000, autovacuum_analyze_scale_factor = 0.05, autovacuum_analyze_threshold = 2000);

CREATE TABLE IF NOT EXISTS Instances_0042 PARTITION OF Instances FOR VALUES WITH (MODULUS 128, REMAINDER 42);
ALTER TABLE Instances_0042 SET (fillfactor = 70);
ALTER TABLE Instances_0042 SET (autovacuum_vacuum_scale_factor = 0.05, autovacuum_vacuum_threshold = 5000, autovacuum_analyze_scale_factor = 0.05, autovacuum_analyze_threshold = 2000);

CREATE TABLE IF NOT EXISTS Instances_0043 PARTITION OF Instances FOR VALUES WITH (MODULUS 128, REMAINDER 43);
ALTER TABLE Instances_0043 SET (fillfactor = 70);
ALTER TABLE Instances_0043 SET (autovacuum_vacuum_scale_factor = 0.05, autovacuum_vacuum_threshold = 5000, autovacuum_analyze_scale_factor = 0.05, autovacuum_analyze_threshold = 2000);

CREATE TABLE IF NOT EXISTS Instances_0044 PARTITION OF Instances FOR VALUES WITH (MODULUS 128, REMAINDER 44);
ALTER TABLE Instances_0044 SET (fillfactor = 70);
ALTER TABLE Instances_0044 SET (autovacuum_vacuum_scale_factor = 0.05, autovacuum_vacuum_threshold = 5000, autovacuum_analyze_scale_factor = 0.05, autovacuum_analyze_threshold = 2000);

CREATE TABLE IF NOT EXISTS Instances_0045 PARTITION OF Instances FOR VALUES WITH (MODULUS 128, REMAINDER 45);
ALTER TABLE Instances_0045 SET (fillfactor = 70);
ALTER TABLE Instances_0045 SET (autovacuum_vacuum_scale_factor = 0.05, autovacuum_vacuum_threshold = 5000, autovacuum_analyze_scale_factor = 0.05, autovacuum_analyze_threshold = 2000);

CREATE TABLE IF NOT EXISTS Instances_0046 PARTITION OF Instances FOR VALUES WITH (MODULUS 128, REMAINDER 46);
ALTER TABLE Instances_0046 SET (fillfactor = 70);
ALTER TABLE Instances_0046 SET (autovacuum_vacuum_scale_factor = 0.05, autovacuum_vacuum_threshold = 5000, autovacuum_analyze_scale_factor = 0.05, autovacuum_analyze_threshold = 2000);

CREATE TABLE IF NOT EXISTS Instances_0047 PARTITION OF Instances FOR VALUES WITH (MODULUS 128, REMAINDER 47);
ALTER TABLE Instances_0047 SET (fillfactor = 70);
ALTER TABLE Instances_0047 SET (autovacuum_vacuum_scale_factor = 0.05, autovacuum_vacuum_threshold = 5000, autovacuum_analyze_scale_factor = 0.05, autovacuum_analyze_threshold = 2000);

CREATE TABLE IF NOT EXISTS Instances_0048 PARTITION OF Instances FOR VALUES WITH (MODULUS 128, REMAINDER 48);
ALTER TABLE Instances_0048 SET (fillfactor = 70);
ALTER TABLE Instances_0048 SET (autovacuum_vacuum_scale_factor = 0.05, autovacuum_vacuum_threshold = 5000, autovacuum_analyze_scale_factor = 0.05, autovacuum_analyze_threshold = 2000);

CREATE TABLE IF NOT EXISTS Instances_0049 PARTITION OF Instances FOR VALUES WITH (MODULUS 128, REMAINDER 49);
ALTER TABLE Instances_0049 SET (fillfactor = 70);
ALTER TABLE Instances_0049 SET (autovacuum_vacuum_scale_factor = 0.05, autovacuum_vacuum_threshold = 5000, autovacuum_analyze_scale_factor = 0.05, autovacuum_analyze_threshold = 2000);

CREATE TABLE IF NOT EXISTS Instances_0050 PARTITION OF Instances FOR VALUES WITH (MODULUS 128, REMAINDER 50);
ALTER TABLE Instances_0050 SET (fillfactor = 70);
ALTER TABLE Instances_0050 SET (autovacuum_vacuum_scale_factor = 0.05, autovacuum_vacuum_threshold = 5000, autovacuum_analyze_scale_factor = 0.05, autovacuum_analyze_threshold = 2000);

CREATE TABLE IF NOT EXISTS Instances_0051 PARTITION OF Instances FOR VALUES WITH (MODULUS 128, REMAINDER 51);
ALTER TABLE Instances_0051 SET (fillfactor = 70);
ALTER TABLE Instances_0051 SET (autovacuum_vacuum_scale_factor = 0.05, autovacuum_vacuum_threshold = 5000, autovacuum_analyze_scale_factor = 0.05, autovacuum_analyze_threshold = 2000);

CREATE TABLE IF NOT EXISTS Instances_0052 PARTITION OF Instances FOR VALUES WITH (MODULUS 128, REMAINDER 52);
ALTER TABLE Instances_0052 SET (fillfactor = 70);
ALTER TABLE Instances_0052 SET (autovacuum_vacuum_scale_factor = 0.05, autovacuum_vacuum_threshold = 5000, autovacuum_analyze_scale_factor = 0.05, autovacuum_analyze_threshold = 2000);

CREATE TABLE IF NOT EXISTS Instances_0053 PARTITION OF Instances FOR VALUES WITH (MODULUS 128, REMAINDER 53);
ALTER TABLE Instances_0053 SET (fillfactor = 70);
ALTER TABLE Instances_0053 SET (autovacuum_vacuum_scale_factor = 0.05, autovacuum_vacuum_threshold = 5000, autovacuum_analyze_scale_factor = 0.05, autovacuum_analyze_threshold = 2000);

CREATE TABLE IF NOT EXISTS Instances_0054 PARTITION OF Instances FOR VALUES WITH (MODULUS 128, REMAINDER 54);
ALTER TABLE Instances_0054 SET (fillfactor = 70);
ALTER TABLE Instances_0054 SET (autovacuum_vacuum_scale_factor = 0.05, autovacuum_vacuum_threshold = 5000, autovacuum_analyze_scale_factor = 0.05, autovacuum_analyze_threshold = 2000);

CREATE TABLE IF NOT EXISTS Instances_0055 PARTITION OF Instances FOR VALUES WITH (MODULUS 128, REMAINDER 55);
ALTER TABLE Instances_0055 SET (fillfactor = 70);
ALTER TABLE Instances_0055 SET (autovacuum_vacuum_scale_factor = 0.05, autovacuum_vacuum_threshold = 5000, autovacuum_analyze_scale_factor = 0.05, autovacuum_analyze_threshold = 2000);

CREATE TABLE IF NOT EXISTS Instances_0056 PARTITION OF Instances FOR VALUES WITH (MODULUS 128, REMAINDER 56);
ALTER TABLE Instances_0056 SET (fillfactor = 70);
ALTER TABLE Instances_0056 SET (autovacuum_vacuum_scale_factor = 0.05, autovacuum_vacuum_threshold = 5000, autovacuum_analyze_scale_factor = 0.05, autovacuum_analyze_threshold = 2000);

CREATE TABLE IF NOT EXISTS Instances_0057 PARTITION OF Instances FOR VALUES WITH (MODULUS 128, REMAINDER 57);
ALTER TABLE Instances_0057 SET (fillfactor = 70);
ALTER TABLE Instances_0057 SET (autovacuum_vacuum_scale_factor = 0.05, autovacuum_vacuum_threshold = 5000, autovacuum_analyze_scale_factor = 0.05, autovacuum_analyze_threshold = 2000);

CREATE TABLE IF NOT EXISTS Instances_0058 PARTITION OF Instances FOR VALUES WITH (MODULUS 128, REMAINDER 58);
ALTER TABLE Instances_0058 SET (fillfactor = 70);
ALTER TABLE Instances_0058 SET (autovacuum_vacuum_scale_factor = 0.05, autovacuum_vacuum_threshold = 5000, autovacuum_analyze_scale_factor = 0.05, autovacuum_analyze_threshold = 2000);

CREATE TABLE IF NOT EXISTS Instances_0059 PARTITION OF Instances FOR VALUES WITH (MODULUS 128, REMAINDER 59);
ALTER TABLE Instances_0059 SET (fillfactor = 70);
ALTER TABLE Instances_0059 SET (autovacuum_vacuum_scale_factor = 0.05, autovacuum_vacuum_threshold = 5000, autovacuum_analyze_scale_factor = 0.05, autovacuum_analyze_threshold = 2000);

CREATE TABLE IF NOT EXISTS Instances_0060 PARTITION OF Instances FOR VALUES WITH (MODULUS 128, REMAINDER 60);
ALTER TABLE Instances_0060 SET (fillfactor = 70);
ALTER TABLE Instances_0060 SET (autovacuum_vacuum_scale_factor = 0.05, autovacuum_vacuum_threshold = 5000, autovacuum_analyze_scale_factor = 0.05, autovacuum_analyze_threshold = 2000);

CREATE TABLE IF NOT EXISTS Instances_0061 PARTITION OF Instances FOR VALUES WITH (MODULUS 128, REMAINDER 61);
ALTER TABLE Instances_0061 SET (fillfactor = 70);
ALTER TABLE Instances_0061 SET (autovacuum_vacuum_scale_factor = 0.05, autovacuum_vacuum_threshold = 5000, autovacuum_analyze_scale_factor = 0.05, autovacuum_analyze_threshold = 2000);

CREATE TABLE IF NOT EXISTS Instances_0062 PARTITION OF Instances FOR VALUES WITH (MODULUS 128, REMAINDER 62);
ALTER TABLE Instances_0062 SET (fillfactor = 70);
ALTER TABLE Instances_0062 SET (autovacuum_vacuum_scale_factor = 0.05, autovacuum_vacuum_threshold = 5000, autovacuum_analyze_scale_factor = 0.05, autovacuum_analyze_threshold = 2000);

CREATE TABLE IF NOT EXISTS Instances_0063 PARTITION OF Instances FOR VALUES WITH (MODULUS 128, REMAINDER 63);
ALTER TABLE Instances_0063 SET (fillfactor = 70);
ALTER TABLE Instances_0063 SET (autovacuum_vacuum_scale_factor = 0.05, autovacuum_vacuum_threshold = 5000, autovacuum_analyze_scale_factor = 0.05, autovacuum_analyze_threshold = 2000);

CREATE TABLE IF NOT EXISTS Instances_0064 PARTITION OF Instances FOR VALUES WITH (MODULUS 128, REMAINDER 64);
ALTER TABLE Instances_0064 SET (fillfactor = 70);
ALTER TABLE Instances_0064 SET (autovacuum_vacuum_scale_factor = 0.05, autovacuum_vacuum_threshold = 5000, autovacuum_analyze_scale_factor = 0.05, autovacuum_analyze_threshold = 2000);

CREATE TABLE IF NOT EXISTS Instances_0065 PARTITION OF Instances FOR VALUES WITH (MODULUS 128, REMAINDER 65);
ALTER TABLE Instances_0065 SET (fillfactor = 70);
ALTER TABLE Instances_0065 SET (autovacuum_vacuum_scale_factor = 0.05, autovacuum_vacuum_threshold = 5000, autovacuum_analyze_scale_factor = 0.05, autovacuum_analyze_threshold = 2000);

CREATE TABLE IF NOT EXISTS Instances_0066 PARTITION OF Instances FOR VALUES WITH (MODULUS 128, REMAINDER 66);
ALTER TABLE Instances_0066 SET (fillfactor = 70);
ALTER TABLE Instances_0066 SET (autovacuum_vacuum_scale_factor = 0.05, autovacuum_vacuum_threshold = 5000, autovacuum_analyze_scale_factor = 0.05, autovacuum_analyze_threshold = 2000);

CREATE TABLE IF NOT EXISTS Instances_0067 PARTITION OF Instances FOR VALUES WITH (MODULUS 128, REMAINDER 67);
ALTER TABLE Instances_0067 SET (fillfactor = 70);
ALTER TABLE Instances_0067 SET (autovacuum_vacuum_scale_factor = 0.05, autovacuum_vacuum_threshold = 5000, autovacuum_analyze_scale_factor = 0.05, autovacuum_analyze_threshold = 2000);

CREATE TABLE IF NOT EXISTS Instances_0068 PARTITION OF Instances FOR VALUES WITH (MODULUS 128, REMAINDER 68);
ALTER TABLE Instances_0068 SET (fillfactor = 70);
ALTER TABLE Instances_0068 SET (autovacuum_vacuum_scale_factor = 0.05, autovacuum_vacuum_threshold = 5000, autovacuum_analyze_scale_factor = 0.05, autovacuum_analyze_threshold = 2000);

CREATE TABLE IF NOT EXISTS Instances_0069 PARTITION OF Instances FOR VALUES WITH (MODULUS 128, REMAINDER 69);
ALTER TABLE Instances_0069 SET (fillfactor = 70);
ALTER TABLE Instances_0069 SET (autovacuum_vacuum_scale_factor = 0.05, autovacuum_vacuum_threshold = 5000, autovacuum_analyze_scale_factor = 0.05, autovacuum_analyze_threshold = 2000);

CREATE TABLE IF NOT EXISTS Instances_0070 PARTITION OF Instances FOR VALUES WITH (MODULUS 128, REMAINDER 70);
ALTER TABLE Instances_0070 SET (fillfactor = 70);
ALTER TABLE Instances_0070 SET (autovacuum_vacuum_scale_factor = 0.05, autovacuum_vacuum_threshold = 5000, autovacuum_analyze_scale_factor = 0.05, autovacuum_analyze_threshold = 2000);

CREATE TABLE IF NOT EXISTS Instances_0071 PARTITION OF Instances FOR VALUES WITH (MODULUS 128, REMAINDER 71);
ALTER TABLE Instances_0071 SET (fillfactor = 70);
ALTER TABLE Instances_0071 SET (autovacuum_vacuum_scale_factor = 0.05, autovacuum_vacuum_threshold = 5000, autovacuum_analyze_scale_factor = 0.05, autovacuum_analyze_threshold = 2000);

CREATE TABLE IF NOT EXISTS Instances_0072 PARTITION OF Instances FOR VALUES WITH (MODULUS 128, REMAINDER 72);
ALTER TABLE Instances_0072 SET (fillfactor = 70);
ALTER TABLE Instances_0072 SET (autovacuum_vacuum_scale_factor = 0.05, autovacuum_vacuum_threshold = 5000, autovacuum_analyze_scale_factor = 0.05, autovacuum_analyze_threshold = 2000);

CREATE TABLE IF NOT EXISTS Instances_0073 PARTITION OF Instances FOR VALUES WITH (MODULUS 128, REMAINDER 73);
ALTER TABLE Instances_0073 SET (fillfactor = 70);
ALTER TABLE Instances_0073 SET (autovacuum_vacuum_scale_factor = 0.05, autovacuum_vacuum_threshold = 5000, autovacuum_analyze_scale_factor = 0.05, autovacuum_analyze_threshold = 2000);

CREATE TABLE IF NOT EXISTS Instances_0074 PARTITION OF Instances FOR VALUES WITH (MODULUS 128, REMAINDER 74);
ALTER TABLE Instances_0074 SET (fillfactor = 70);
ALTER TABLE Instances_0074 SET (autovacuum_vacuum_scale_factor = 0.05, autovacuum_vacuum_threshold = 5000, autovacuum_analyze_scale_factor = 0.05, autovacuum_analyze_threshold = 2000);

CREATE TABLE IF NOT EXISTS Instances_0075 PARTITION OF Instances FOR VALUES WITH (MODULUS 128, REMAINDER 75);
ALTER TABLE Instances_0075 SET (fillfactor = 70);
ALTER TABLE Instances_0075 SET (autovacuum_vacuum_scale_factor = 0.05, autovacuum_vacuum_threshold = 5000, autovacuum_analyze_scale_factor = 0.05, autovacuum_analyze_threshold = 2000);

CREATE TABLE IF NOT EXISTS Instances_0076 PARTITION OF Instances FOR VALUES WITH (MODULUS 128, REMAINDER 76);
ALTER TABLE Instances_0076 SET (fillfactor = 70);
ALTER TABLE Instances_0076 SET (autovacuum_vacuum_scale_factor = 0.05, autovacuum_vacuum_threshold = 5000, autovacuum_analyze_scale_factor = 0.05, autovacuum_analyze_threshold = 2000);

CREATE TABLE IF NOT EXISTS Instances_0077 PARTITION OF Instances FOR VALUES WITH (MODULUS 128, REMAINDER 77);
ALTER TABLE Instances_0077 SET (fillfactor = 70);
ALTER TABLE Instances_0077 SET (autovacuum_vacuum_scale_factor = 0.05, autovacuum_vacuum_threshold = 5000, autovacuum_analyze_scale_factor = 0.05, autovacuum_analyze_threshold = 2000);

CREATE TABLE IF NOT EXISTS Instances_0078 PARTITION OF Instances FOR VALUES WITH (MODULUS 128, REMAINDER 78);
ALTER TABLE Instances_0078 SET (fillfactor = 70);
ALTER TABLE Instances_0078 SET (autovacuum_vacuum_scale_factor = 0.05, autovacuum_vacuum_threshold = 5000, autovacuum_analyze_scale_factor = 0.05, autovacuum_analyze_threshold = 2000);

CREATE TABLE IF NOT EXISTS Instances_0079 PARTITION OF Instances FOR VALUES WITH (MODULUS 128, REMAINDER 79);
ALTER TABLE Instances_0079 SET (fillfactor = 70);
ALTER TABLE Instances_0079 SET (autovacuum_vacuum_scale_factor = 0.05, autovacuum_vacuum_threshold = 5000, autovacuum_analyze_scale_factor = 0.05, autovacuum_analyze_threshold = 2000);

CREATE TABLE IF NOT EXISTS Instances_0080 PARTITION OF Instances FOR VALUES WITH (MODULUS 128, REMAINDER 80);
ALTER TABLE Instances_0080 SET (fillfactor = 70);
ALTER TABLE Instances_0080 SET (autovacuum_vacuum_scale_factor = 0.05, autovacuum_vacuum_threshold = 5000, autovacuum_analyze_scale_factor = 0.05, autovacuum_analyze_threshold = 2000);

CREATE TABLE IF NOT EXISTS Instances_0081 PARTITION OF Instances FOR VALUES WITH (MODULUS 128, REMAINDER 81);
ALTER TABLE Instances_0081 SET (fillfactor = 70);
ALTER TABLE Instances_0081 SET (autovacuum_vacuum_scale_factor = 0.05, autovacuum_vacuum_threshold = 5000, autovacuum_analyze_scale_factor = 0.05, autovacuum_analyze_threshold = 2000);

CREATE TABLE IF NOT EXISTS Instances_0082 PARTITION OF Instances FOR VALUES WITH (MODULUS 128, REMAINDER 82);
ALTER TABLE Instances_0082 SET (fillfactor = 70);
ALTER TABLE Instances_0082 SET (autovacuum_vacuum_scale_factor = 0.05, autovacuum_vacuum_threshold = 5000, autovacuum_analyze_scale_factor = 0.05, autovacuum_analyze_threshold = 2000);

CREATE TABLE IF NOT EXISTS Instances_0083 PARTITION OF Instances FOR VALUES WITH (MODULUS 128, REMAINDER 83);
ALTER TABLE Instances_0083 SET (fillfactor = 70);
ALTER TABLE Instances_0083 SET (autovacuum_vacuum_scale_factor = 0.05, autovacuum_vacuum_threshold = 5000, autovacuum_analyze_scale_factor = 0.05, autovacuum_analyze_threshold = 2000);

CREATE TABLE IF NOT EXISTS Instances_0084 PARTITION OF Instances FOR VALUES WITH (MODULUS 128, REMAINDER 84);
ALTER TABLE Instances_0084 SET (fillfactor = 70);
ALTER TABLE Instances_0084 SET (autovacuum_vacuum_scale_factor = 0.05, autovacuum_vacuum_threshold = 5000, autovacuum_analyze_scale_factor = 0.05, autovacuum_analyze_threshold = 2000);

CREATE TABLE IF NOT EXISTS Instances_0085 PARTITION OF Instances FOR VALUES WITH (MODULUS 128, REMAINDER 85);
ALTER TABLE Instances_0085 SET (fillfactor = 70);
ALTER TABLE Instances_0085 SET (autovacuum_vacuum_scale_factor = 0.05, autovacuum_vacuum_threshold = 5000, autovacuum_analyze_scale_factor = 0.05, autovacuum_analyze_threshold = 2000);

CREATE TABLE IF NOT EXISTS Instances_0086 PARTITION OF Instances FOR VALUES WITH (MODULUS 128, REMAINDER 86);
ALTER TABLE Instances_0086 SET (fillfactor = 70);
ALTER TABLE Instances_0086 SET (autovacuum_vacuum_scale_factor = 0.05, autovacuum_vacuum_threshold = 5000, autovacuum_analyze_scale_factor = 0.05, autovacuum_analyze_threshold = 2000);

CREATE TABLE IF NOT EXISTS Instances_0087 PARTITION OF Instances FOR VALUES WITH (MODULUS 128, REMAINDER 87);
ALTER TABLE Instances_0087 SET (fillfactor = 70);
ALTER TABLE Instances_0087 SET (autovacuum_vacuum_scale_factor = 0.05, autovacuum_vacuum_threshold = 5000, autovacuum_analyze_scale_factor = 0.05, autovacuum_analyze_threshold = 2000);

CREATE TABLE IF NOT EXISTS Instances_0088 PARTITION OF Instances FOR VALUES WITH (MODULUS 128, REMAINDER 88);
ALTER TABLE Instances_0088 SET (fillfactor = 70);
ALTER TABLE Instances_0088 SET (autovacuum_vacuum_scale_factor = 0.05, autovacuum_vacuum_threshold = 5000, autovacuum_analyze_scale_factor = 0.05, autovacuum_analyze_threshold = 2000);

CREATE TABLE IF NOT EXISTS Instances_0089 PARTITION OF Instances FOR VALUES WITH (MODULUS 128, REMAINDER 89);
ALTER TABLE Instances_0089 SET (fillfactor = 70);
ALTER TABLE Instances_0089 SET (autovacuum_vacuum_scale_factor = 0.05, autovacuum_vacuum_threshold = 5000, autovacuum_analyze_scale_factor = 0.05, autovacuum_analyze_threshold = 2000);

CREATE TABLE IF NOT EXISTS Instances_0090 PARTITION OF Instances FOR VALUES WITH (MODULUS 128, REMAINDER 90);
ALTER TABLE Instances_0090 SET (fillfactor = 70);
ALTER TABLE Instances_0090 SET (autovacuum_vacuum_scale_factor = 0.05, autovacuum_vacuum_threshold = 5000, autovacuum_analyze_scale_factor = 0.05, autovacuum_analyze_threshold = 2000);

CREATE TABLE IF NOT EXISTS Instances_0091 PARTITION OF Instances FOR VALUES WITH (MODULUS 128, REMAINDER 91);
ALTER TABLE Instances_0091 SET (fillfactor = 70);
ALTER TABLE Instances_0091 SET (autovacuum_vacuum_scale_factor = 0.05, autovacuum_vacuum_threshold = 5000, autovacuum_analyze_scale_factor = 0.05, autovacuum_analyze_threshold = 2000);

CREATE TABLE IF NOT EXISTS Instances_0092 PARTITION OF Instances FOR VALUES WITH (MODULUS 128, REMAINDER 92);
ALTER TABLE Instances_0092 SET (fillfactor = 70);
ALTER TABLE Instances_0092 SET (autovacuum_vacuum_scale_factor = 0.05, autovacuum_vacuum_threshold = 5000, autovacuum_analyze_scale_factor = 0.05, autovacuum_analyze_threshold = 2000);

CREATE TABLE IF NOT EXISTS Instances_0093 PARTITION OF Instances FOR VALUES WITH (MODULUS 128, REMAINDER 93);
ALTER TABLE Instances_0093 SET (fillfactor = 70);
ALTER TABLE Instances_0093 SET (autovacuum_vacuum_scale_factor = 0.05, autovacuum_vacuum_threshold = 5000, autovacuum_analyze_scale_factor = 0.05, autovacuum_analyze_threshold = 2000);

CREATE TABLE IF NOT EXISTS Instances_0094 PARTITION OF Instances FOR VALUES WITH (MODULUS 128, REMAINDER 94);
ALTER TABLE Instances_0094 SET (fillfactor = 70);
ALTER TABLE Instances_0094 SET (autovacuum_vacuum_scale_factor = 0.05, autovacuum_vacuum_threshold = 5000, autovacuum_analyze_scale_factor = 0.05, autovacuum_analyze_threshold = 2000);

CREATE TABLE IF NOT EXISTS Instances_0095 PARTITION OF Instances FOR VALUES WITH (MODULUS 128, REMAINDER 95);
ALTER TABLE Instances_0095 SET (fillfactor = 70);
ALTER TABLE Instances_0095 SET (autovacuum_vacuum_scale_factor = 0.05, autovacuum_vacuum_threshold = 5000, autovacuum_analyze_scale_factor = 0.05, autovacuum_analyze_threshold = 2000);

CREATE TABLE IF NOT EXISTS Instances_0096 PARTITION OF Instances FOR VALUES WITH (MODULUS 128, REMAINDER 96);
ALTER TABLE Instances_0096 SET (fillfactor = 70);
ALTER TABLE Instances_0096 SET (autovacuum_vacuum_scale_factor = 0.05, autovacuum_vacuum_threshold = 5000, autovacuum_analyze_scale_factor = 0.05, autovacuum_analyze_threshold = 2000);

CREATE TABLE IF NOT EXISTS Instances_0097 PARTITION OF Instances FOR VALUES WITH (MODULUS 128, REMAINDER 97);
ALTER TABLE Instances_0097 SET (fillfactor = 70);
ALTER TABLE Instances_0097 SET (autovacuum_vacuum_scale_factor = 0.05, autovacuum_vacuum_threshold = 5000, autovacuum_analyze_scale_factor = 0.05, autovacuum_analyze_threshold = 2000);

CREATE TABLE IF NOT EXISTS Instances_0098 PARTITION OF Instances FOR VALUES WITH (MODULUS 128, REMAINDER 98);
ALTER TABLE Instances_0098 SET (fillfactor = 70);
ALTER TABLE Instances_0098 SET (autovacuum_vacuum_scale_factor = 0.05, autovacuum_vacuum_threshold = 5000, autovacuum_analyze_scale_factor = 0.05, autovacuum_analyze_threshold = 2000);

CREATE TABLE IF NOT EXISTS Instances_0099 PARTITION OF Instances FOR VALUES WITH (MODULUS 128, REMAINDER 99);
ALTER TABLE Instances_0099 SET (fillfactor = 70);
ALTER TABLE Instances_0099 SET (autovacuum_vacuum_scale_factor = 0.05, autovacuum_vacuum_threshold = 5000, autovacuum_analyze_scale_factor = 0.05, autovacuum_analyze_threshold = 2000);

CREATE TABLE IF NOT EXISTS Instances_0100 PARTITION OF Instances FOR VALUES WITH (MODULUS 128, REMAINDER 100);
ALTER TABLE Instances_0100 SET (fillfactor = 70);
ALTER TABLE Instances_0100 SET (autovacuum_vacuum_scale_factor = 0.05, autovacuum_vacuum_threshold = 5000, autovacuum_analyze_scale_factor = 0.05, autovacuum_analyze_threshold = 2000);

CREATE TABLE IF NOT EXISTS Instances_0101 PARTITION OF Instances FOR VALUES WITH (MODULUS 128, REMAINDER 101);
ALTER TABLE Instances_0101 SET (fillfactor = 70);
ALTER TABLE Instances_0101 SET (autovacuum_vacuum_scale_factor = 0.05, autovacuum_vacuum_threshold = 5000, autovacuum_analyze_scale_factor = 0.05, autovacuum_analyze_threshold = 2000);

CREATE TABLE IF NOT EXISTS Instances_0102 PARTITION OF Instances FOR VALUES WITH (MODULUS 128, REMAINDER 102);
ALTER TABLE Instances_0102 SET (fillfactor = 70);
ALTER TABLE Instances_0102 SET (autovacuum_vacuum_scale_factor = 0.05, autovacuum_vacuum_threshold = 5000, autovacuum_analyze_scale_factor = 0.05, autovacuum_analyze_threshold = 2000);

CREATE TABLE IF NOT EXISTS Instances_0103 PARTITION OF Instances FOR VALUES WITH (MODULUS 128, REMAINDER 103);
ALTER TABLE Instances_0103 SET (fillfactor = 70);
ALTER TABLE Instances_0103 SET (autovacuum_vacuum_scale_factor = 0.05, autovacuum_vacuum_threshold = 5000, autovacuum_analyze_scale_factor = 0.05, autovacuum_analyze_threshold = 2000);

CREATE TABLE IF NOT EXISTS Instances_0104 PARTITION OF Instances FOR VALUES WITH (MODULUS 128, REMAINDER 104);
ALTER TABLE Instances_0104 SET (fillfactor = 70);
ALTER TABLE Instances_0104 SET (autovacuum_vacuum_scale_factor = 0.05, autovacuum_vacuum_threshold = 5000, autovacuum_analyze_scale_factor = 0.05, autovacuum_analyze_threshold = 2000);

CREATE TABLE IF NOT EXISTS Instances_0105 PARTITION OF Instances FOR VALUES WITH (MODULUS 128, REMAINDER 105);
ALTER TABLE Instances_0105 SET (fillfactor = 70);
ALTER TABLE Instances_0105 SET (autovacuum_vacuum_scale_factor = 0.05, autovacuum_vacuum_threshold = 5000, autovacuum_analyze_scale_factor = 0.05, autovacuum_analyze_threshold = 2000);

CREATE TABLE IF NOT EXISTS Instances_0106 PARTITION OF Instances FOR VALUES WITH (MODULUS 128, REMAINDER 106);
ALTER TABLE Instances_0106 SET (fillfactor = 70);
ALTER TABLE Instances_0106 SET (autovacuum_vacuum_scale_factor = 0.05, autovacuum_vacuum_threshold = 5000, autovacuum_analyze_scale_factor = 0.05, autovacuum_analyze_threshold = 2000);

CREATE TABLE IF NOT EXISTS Instances_0107 PARTITION OF Instances FOR VALUES WITH (MODULUS 128, REMAINDER 107);
ALTER TABLE Instances_0107 SET (fillfactor = 70);
ALTER TABLE Instances_0107 SET (autovacuum_vacuum_scale_factor = 0.05, autovacuum_vacuum_threshold = 5000, autovacuum_analyze_scale_factor = 0.05, autovacuum_analyze_threshold = 2000);

CREATE TABLE IF NOT EXISTS Instances_0108 PARTITION OF Instances FOR VALUES WITH (MODULUS 128, REMAINDER 108);
ALTER TABLE Instances_0108 SET (fillfactor = 70);
ALTER TABLE Instances_0108 SET (autovacuum_vacuum_scale_factor = 0.05, autovacuum_vacuum_threshold = 5000, autovacuum_analyze_scale_factor = 0.05, autovacuum_analyze_threshold = 2000);

CREATE TABLE IF NOT EXISTS Instances_0109 PARTITION OF Instances FOR VALUES WITH (MODULUS 128, REMAINDER 109);
ALTER TABLE Instances_0109 SET (fillfactor = 70);
ALTER TABLE Instances_0109 SET (autovacuum_vacuum_scale_factor = 0.05, autovacuum_vacuum_threshold = 5000, autovacuum_analyze_scale_factor = 0.05, autovacuum_analyze_threshold = 2000);

CREATE TABLE IF NOT EXISTS Instances_0110 PARTITION OF Instances FOR VALUES WITH (MODULUS 128, REMAINDER 110);
ALTER TABLE Instances_0110 SET (fillfactor = 70);
ALTER TABLE Instances_0110 SET (autovacuum_vacuum_scale_factor = 0.05, autovacuum_vacuum_threshold = 5000, autovacuum_analyze_scale_factor = 0.05, autovacuum_analyze_threshold = 2000);

CREATE TABLE IF NOT EXISTS Instances_0111 PARTITION OF Instances FOR VALUES WITH (MODULUS 128, REMAINDER 111);
ALTER TABLE Instances_0111 SET (fillfactor = 70);
ALTER TABLE Instances_0111 SET (autovacuum_vacuum_scale_factor = 0.05, autovacuum_vacuum_threshold = 5000, autovacuum_analyze_scale_factor = 0.05, autovacuum_analyze_threshold = 2000);

CREATE TABLE IF NOT EXISTS Instances_0112 PARTITION OF Instances FOR VALUES WITH (MODULUS 128, REMAINDER 112);
ALTER TABLE Instances_0112 SET (fillfactor = 70);
ALTER TABLE Instances_0112 SET (autovacuum_vacuum_scale_factor = 0.05, autovacuum_vacuum_threshold = 5000, autovacuum_analyze_scale_factor = 0.05, autovacuum_analyze_threshold = 2000);

CREATE TABLE IF NOT EXISTS Instances_0113 PARTITION OF Instances FOR VALUES WITH (MODULUS 128, REMAINDER 113);
ALTER TABLE Instances_0113 SET (fillfactor = 70);
ALTER TABLE Instances_0113 SET (autovacuum_vacuum_scale_factor = 0.05, autovacuum_vacuum_threshold = 5000, autovacuum_analyze_scale_factor = 0.05, autovacuum_analyze_threshold = 2000);

CREATE TABLE IF NOT EXISTS Instances_0114 PARTITION OF Instances FOR VALUES WITH (MODULUS 128, REMAINDER 114);
ALTER TABLE Instances_0114 SET (fillfactor = 70);
ALTER TABLE Instances_0114 SET (autovacuum_vacuum_scale_factor = 0.05, autovacuum_vacuum_threshold = 5000, autovacuum_analyze_scale_factor = 0.05, autovacuum_analyze_threshold = 2000);

CREATE TABLE IF NOT EXISTS Instances_0115 PARTITION OF Instances FOR VALUES WITH (MODULUS 128, REMAINDER 115);
ALTER TABLE Instances_0115 SET (fillfactor = 70);
ALTER TABLE Instances_0115 SET (autovacuum_vacuum_scale_factor = 0.05, autovacuum_vacuum_threshold = 5000, autovacuum_analyze_scale_factor = 0.05, autovacuum_analyze_threshold = 2000);

CREATE TABLE IF NOT EXISTS Instances_0116 PARTITION OF Instances FOR VALUES WITH (MODULUS 128, REMAINDER 116);
ALTER TABLE Instances_0116 SET (fillfactor = 70);
ALTER TABLE Instances_0116 SET (autovacuum_vacuum_scale_factor = 0.05, autovacuum_vacuum_threshold = 5000, autovacuum_analyze_scale_factor = 0.05, autovacuum_analyze_threshold = 2000);

CREATE TABLE IF NOT EXISTS Instances_0117 PARTITION OF Instances FOR VALUES WITH (MODULUS 128, REMAINDER 117);
ALTER TABLE Instances_0117 SET (fillfactor = 70);
ALTER TABLE Instances_0117 SET (autovacuum_vacuum_scale_factor = 0.05, autovacuum_vacuum_threshold = 5000, autovacuum_analyze_scale_factor = 0.05, autovacuum_analyze_threshold = 2000);

CREATE TABLE IF NOT EXISTS Instances_0118 PARTITION OF Instances FOR VALUES WITH (MODULUS 128, REMAINDER 118);
ALTER TABLE Instances_0118 SET (fillfactor = 70);
ALTER TABLE Instances_0118 SET (autovacuum_vacuum_scale_factor = 0.05, autovacuum_vacuum_threshold = 5000, autovacuum_analyze_scale_factor = 0.05, autovacuum_analyze_threshold = 2000);

CREATE TABLE IF NOT EXISTS Instances_0119 PARTITION OF Instances FOR VALUES WITH (MODULUS 128, REMAINDER 119);
ALTER TABLE Instances_0119 SET (fillfactor = 70);
ALTER TABLE Instances_0119 SET (autovacuum_vacuum_scale_factor = 0.05, autovacuum_vacuum_threshold = 5000, autovacuum_analyze_scale_factor = 0.05, autovacuum_analyze_threshold = 2000);

CREATE TABLE IF NOT EXISTS Instances_0120 PARTITION OF Instances FOR VALUES WITH (MODULUS 128, REMAINDER 120);
ALTER TABLE Instances_0120 SET (fillfactor = 70);
ALTER TABLE Instances_0120 SET (autovacuum_vacuum_scale_factor = 0.05, autovacuum_vacuum_threshold = 5000, autovacuum_analyze_scale_factor = 0.05, autovacuum_analyze_threshold = 2000);

CREATE TABLE IF NOT EXISTS Instances_0121 PARTITION OF Instances FOR VALUES WITH (MODULUS 128, REMAINDER 121);
ALTER TABLE Instances_0121 SET (fillfactor = 70);
ALTER TABLE Instances_0121 SET (autovacuum_vacuum_scale_factor = 0.05, autovacuum_vacuum_threshold = 5000, autovacuum_analyze_scale_factor = 0.05, autovacuum_analyze_threshold = 2000);

CREATE TABLE IF NOT EXISTS Instances_0122 PARTITION OF Instances FOR VALUES WITH (MODULUS 128, REMAINDER 122);
ALTER TABLE Instances_0122 SET (fillfactor = 70);
ALTER TABLE Instances_0122 SET (autovacuum_vacuum_scale_factor = 0.05, autovacuum_vacuum_threshold = 5000, autovacuum_analyze_scale_factor = 0.05, autovacuum_analyze_threshold = 2000);

CREATE TABLE IF NOT EXISTS Instances_0123 PARTITION OF Instances FOR VALUES WITH (MODULUS 128, REMAINDER 123);
ALTER TABLE Instances_0123 SET (fillfactor = 70);
ALTER TABLE Instances_0123 SET (autovacuum_vacuum_scale_factor = 0.05, autovacuum_vacuum_threshold = 5000, autovacuum_analyze_scale_factor = 0.05, autovacuum_analyze_threshold = 2000);

CREATE TABLE IF NOT EXISTS Instances_0124 PARTITION OF Instances FOR VALUES WITH (MODULUS 128, REMAINDER 124);
ALTER TABLE Instances_0124 SET (fillfactor = 70);
ALTER TABLE Instances_0124 SET (autovacuum_vacuum_scale_factor = 0.05, autovacuum_vacuum_threshold = 5000, autovacuum_analyze_scale_factor = 0.05, autovacuum_analyze_threshold = 2000);

CREATE TABLE IF NOT EXISTS Instances_0125 PARTITION OF Instances FOR VALUES WITH (MODULUS 128, REMAINDER 125);
ALTER TABLE Instances_0125 SET (fillfactor = 70);
ALTER TABLE Instances_0125 SET (autovacuum_vacuum_scale_factor = 0.05, autovacuum_vacuum_threshold = 5000, autovacuum_analyze_scale_factor = 0.05, autovacuum_analyze_threshold = 2000);

CREATE TABLE IF NOT EXISTS Instances_0126 PARTITION OF Instances FOR VALUES WITH (MODULUS 128, REMAINDER 126);
ALTER TABLE Instances_0126 SET (fillfactor = 70);
ALTER TABLE Instances_0126 SET (autovacuum_vacuum_scale_factor = 0.05, autovacuum_vacuum_threshold = 5000, autovacuum_analyze_scale_factor = 0.05, autovacuum_analyze_threshold = 2000);

CREATE TABLE IF NOT EXISTS Instances_0127 PARTITION OF Instances FOR VALUES WITH (MODULUS 128, REMAINDER 127);
ALTER TABLE Instances_0127 SET (fillfactor = 70);
ALTER TABLE Instances_0127 SET (autovacuum_vacuum_scale_factor = 0.05, autovacuum_vacuum_threshold = 5000, autovacuum_analyze_scale_factor = 0.05, autovacuum_analyze_threshold = 2000);

-- ============================================================================
-- History Table (with partitioning and performance optimizations)
-- ============================================================================
CREATE TABLE IF NOT EXISTS History (
    InstanceID TEXT NOT NULL,
    SequenceNumber BIGSERIAL NOT NULL,  -- Changed to BIGSERIAL for high scale
    EventPayload BYTEA NOT NULL,

    PRIMARY KEY (InstanceID, SequenceNumber)
) PARTITION BY HASH (InstanceID);

-- Create 128 partitions matching NewEvents for consistency. The PRIMARY KEY (InstanceID, SequenceNumber)
CREATE TABLE IF NOT EXISTS History_0000 PARTITION OF History FOR VALUES WITH (MODULUS 128, REMAINDER 0);
ALTER TABLE History_0000 SET (fillfactor = 100);
ALTER TABLE History_0000 SET (autovacuum_vacuum_scale_factor = 0.1, autovacuum_vacuum_threshold = 1000, autovacuum_analyze_scale_factor = 0.1, autovacuum_analyze_threshold = 1000);
ALTER TABLE History_0000 SET (parallel_workers = 4);

CREATE TABLE IF NOT EXISTS History_0001 PARTITION OF History FOR VALUES WITH (MODULUS 128, REMAINDER 1);
ALTER TABLE History_0001 SET (fillfactor = 100);
ALTER TABLE History_0001 SET (autovacuum_vacuum_scale_factor = 0.1, autovacuum_vacuum_threshold = 1000, autovacuum_analyze_scale_factor = 0.1, autovacuum_analyze_threshold = 1000);
ALTER TABLE History_0001 SET (parallel_workers = 4);

CREATE TABLE IF NOT EXISTS History_0002 PARTITION OF History FOR VALUES WITH (MODULUS 128, REMAINDER 2);
ALTER TABLE History_0002 SET (fillfactor = 100);
ALTER TABLE History_0002 SET (autovacuum_vacuum_scale_factor = 0.1, autovacuum_vacuum_threshold = 1000, autovacuum_analyze_scale_factor = 0.1, autovacuum_analyze_threshold = 1000);
ALTER TABLE History_0002 SET (parallel_workers = 4);

CREATE TABLE IF NOT EXISTS History_0003 PARTITION OF History FOR VALUES WITH (MODULUS 128, REMAINDER 3);
ALTER TABLE History_0003 SET (fillfactor = 100);
ALTER TABLE History_0003 SET (autovacuum_vacuum_scale_factor = 0.1, autovacuum_vacuum_threshold = 1000, autovacuum_analyze_scale_factor = 0.1, autovacuum_analyze_threshold = 1000);
ALTER TABLE History_0003 SET (parallel_workers = 4);

CREATE TABLE IF NOT EXISTS History_0004 PARTITION OF History FOR VALUES WITH (MODULUS 128, REMAINDER 4);
ALTER TABLE History_0004 SET (fillfactor = 100);
ALTER TABLE History_0004 SET (autovacuum_vacuum_scale_factor = 0.1, autovacuum_vacuum_threshold = 1000, autovacuum_analyze_scale_factor = 0.1, autovacuum_analyze_threshold = 1000);
ALTER TABLE History_0004 SET (parallel_workers = 4);

CREATE TABLE IF NOT EXISTS History_0005 PARTITION OF History FOR VALUES WITH (MODULUS 128, REMAINDER 5);
ALTER TABLE History_0005 SET (fillfactor = 100);
ALTER TABLE History_0005 SET (autovacuum_vacuum_scale_factor = 0.1, autovacuum_vacuum_threshold = 1000, autovacuum_analyze_scale_factor = 0.1, autovacuum_analyze_threshold = 1000);
ALTER TABLE History_0005 SET (parallel_workers = 4);

CREATE TABLE IF NOT EXISTS History_0006 PARTITION OF History FOR VALUES WITH (MODULUS 128, REMAINDER 6);
ALTER TABLE History_0006 SET (fillfactor = 100);
ALTER TABLE History_0006 SET (autovacuum_vacuum_scale_factor = 0.1, autovacuum_vacuum_threshold = 1000, autovacuum_analyze_scale_factor = 0.1, autovacuum_analyze_threshold = 1000);
ALTER TABLE History_0006 SET (parallel_workers = 4);

CREATE TABLE IF NOT EXISTS History_0007 PARTITION OF History FOR VALUES WITH (MODULUS 128, REMAINDER 7);
ALTER TABLE History_0007 SET (fillfactor = 100);
ALTER TABLE History_0007 SET (autovacuum_vacuum_scale_factor = 0.1, autovacuum_vacuum_threshold = 1000, autovacuum_analyze_scale_factor = 0.1, autovacuum_analyze_threshold = 1000);
ALTER TABLE History_0007 SET (parallel_workers = 4);

CREATE TABLE IF NOT EXISTS History_0008 PARTITION OF History FOR VALUES WITH (MODULUS 128, REMAINDER 8);
ALTER TABLE History_0008 SET (fillfactor = 100);
ALTER TABLE History_0008 SET (autovacuum_vacuum_scale_factor = 0.1, autovacuum_vacuum_threshold = 1000, autovacuum_analyze_scale_factor = 0.1, autovacuum_analyze_threshold = 1000);
ALTER TABLE History_0008 SET (parallel_workers = 4);

CREATE TABLE IF NOT EXISTS History_0009 PARTITION OF History FOR VALUES WITH (MODULUS 128, REMAINDER 9);
ALTER TABLE History_0009 SET (fillfactor = 100);
ALTER TABLE History_0009 SET (autovacuum_vacuum_scale_factor = 0.1, autovacuum_vacuum_threshold = 1000, autovacuum_analyze_scale_factor = 0.1, autovacuum_analyze_threshold = 1000);
ALTER TABLE History_0009 SET (parallel_workers = 4);

CREATE TABLE IF NOT EXISTS History_0010 PARTITION OF History FOR VALUES WITH (MODULUS 128, REMAINDER 10);
ALTER TABLE History_0010 SET (fillfactor = 100);
ALTER TABLE History_0010 SET (autovacuum_vacuum_scale_factor = 0.1, autovacuum_vacuum_threshold = 1000, autovacuum_analyze_scale_factor = 0.1, autovacuum_analyze_threshold = 1000);
ALTER TABLE History_0010 SET (parallel_workers = 4);

CREATE TABLE IF NOT EXISTS History_0011 PARTITION OF History FOR VALUES WITH (MODULUS 128, REMAINDER 11);
ALTER TABLE History_0011 SET (fillfactor = 100);
ALTER TABLE History_0011 SET (autovacuum_vacuum_scale_factor = 0.1, autovacuum_vacuum_threshold = 1000, autovacuum_analyze_scale_factor = 0.1, autovacuum_analyze_threshold = 1000);
ALTER TABLE History_0011 SET (parallel_workers = 4);

CREATE TABLE IF NOT EXISTS History_0012 PARTITION OF History FOR VALUES WITH (MODULUS 128, REMAINDER 12);
ALTER TABLE History_0012 SET (fillfactor = 100);
ALTER TABLE History_0012 SET (autovacuum_vacuum_scale_factor = 0.1, autovacuum_vacuum_threshold = 1000, autovacuum_analyze_scale_factor = 0.1, autovacuum_analyze_threshold = 1000);
ALTER TABLE History_0012 SET (parallel_workers = 4);

CREATE TABLE IF NOT EXISTS History_0013 PARTITION OF History FOR VALUES WITH (MODULUS 128, REMAINDER 13);
ALTER TABLE History_0013 SET (fillfactor = 100);
ALTER TABLE History_0013 SET (autovacuum_vacuum_scale_factor = 0.1, autovacuum_vacuum_threshold = 1000, autovacuum_analyze_scale_factor = 0.1, autovacuum_analyze_threshold = 1000);
ALTER TABLE History_0013 SET (parallel_workers = 4);

CREATE TABLE IF NOT EXISTS History_0014 PARTITION OF History FOR VALUES WITH (MODULUS 128, REMAINDER 14);
ALTER TABLE History_0014 SET (fillfactor = 100);
ALTER TABLE History_0014 SET (autovacuum_vacuum_scale_factor = 0.1, autovacuum_vacuum_threshold = 1000, autovacuum_analyze_scale_factor = 0.1, autovacuum_analyze_threshold = 1000);
ALTER TABLE History_0014 SET (parallel_workers = 4);

CREATE TABLE IF NOT EXISTS History_0015 PARTITION OF History FOR VALUES WITH (MODULUS 128, REMAINDER 15);
ALTER TABLE History_0015 SET (fillfactor = 100);
ALTER TABLE History_0015 SET (autovacuum_vacuum_scale_factor = 0.1, autovacuum_vacuum_threshold = 1000, autovacuum_analyze_scale_factor = 0.1, autovacuum_analyze_threshold = 1000);
ALTER TABLE History_0015 SET (parallel_workers = 4);

CREATE TABLE IF NOT EXISTS History_0016 PARTITION OF History FOR VALUES WITH (MODULUS 128, REMAINDER 16);
ALTER TABLE History_0016 SET (fillfactor = 100);
ALTER TABLE History_0016 SET (autovacuum_vacuum_scale_factor = 0.1, autovacuum_vacuum_threshold = 1000, autovacuum_analyze_scale_factor = 0.1, autovacuum_analyze_threshold = 1000);
ALTER TABLE History_0016 SET (parallel_workers = 4);

CREATE TABLE IF NOT EXISTS History_0017 PARTITION OF History FOR VALUES WITH (MODULUS 128, REMAINDER 17);
ALTER TABLE History_0017 SET (fillfactor = 100);
ALTER TABLE History_0017 SET (autovacuum_vacuum_scale_factor = 0.1, autovacuum_vacuum_threshold = 1000, autovacuum_analyze_scale_factor = 0.1, autovacuum_analyze_threshold = 1000);
ALTER TABLE History_0017 SET (parallel_workers = 4);

CREATE TABLE IF NOT EXISTS History_0018 PARTITION OF History FOR VALUES WITH (MODULUS 128, REMAINDER 18);
ALTER TABLE History_0018 SET (fillfactor = 100);
ALTER TABLE History_0018 SET (autovacuum_vacuum_scale_factor = 0.1, autovacuum_vacuum_threshold = 1000, autovacuum_analyze_scale_factor = 0.1, autovacuum_analyze_threshold = 1000);
ALTER TABLE History_0018 SET (parallel_workers = 4);

CREATE TABLE IF NOT EXISTS History_0019 PARTITION OF History FOR VALUES WITH (MODULUS 128, REMAINDER 19);
ALTER TABLE History_0019 SET (fillfactor = 100);
ALTER TABLE History_0019 SET (autovacuum_vacuum_scale_factor = 0.1, autovacuum_vacuum_threshold = 1000, autovacuum_analyze_scale_factor = 0.1, autovacuum_analyze_threshold = 1000);
ALTER TABLE History_0019 SET (parallel_workers = 4);

CREATE TABLE IF NOT EXISTS History_0020 PARTITION OF History FOR VALUES WITH (MODULUS 128, REMAINDER 20);
ALTER TABLE History_0020 SET (fillfactor = 100);
ALTER TABLE History_0020 SET (autovacuum_vacuum_scale_factor = 0.1, autovacuum_vacuum_threshold = 1000, autovacuum_analyze_scale_factor = 0.1, autovacuum_analyze_threshold = 1000);
ALTER TABLE History_0020 SET (parallel_workers = 4);

CREATE TABLE IF NOT EXISTS History_0021 PARTITION OF History FOR VALUES WITH (MODULUS 128, REMAINDER 21);
ALTER TABLE History_0021 SET (fillfactor = 100);
ALTER TABLE History_0021 SET (autovacuum_vacuum_scale_factor = 0.1, autovacuum_vacuum_threshold = 1000, autovacuum_analyze_scale_factor = 0.1, autovacuum_analyze_threshold = 1000);
ALTER TABLE History_0021 SET (parallel_workers = 4);

CREATE TABLE IF NOT EXISTS History_0022 PARTITION OF History FOR VALUES WITH (MODULUS 128, REMAINDER 22);
ALTER TABLE History_0022 SET (fillfactor = 100);
ALTER TABLE History_0022 SET (autovacuum_vacuum_scale_factor = 0.1, autovacuum_vacuum_threshold = 1000, autovacuum_analyze_scale_factor = 0.1, autovacuum_analyze_threshold = 1000);
ALTER TABLE History_0022 SET (parallel_workers = 4);

CREATE TABLE IF NOT EXISTS History_0023 PARTITION OF History FOR VALUES WITH (MODULUS 128, REMAINDER 23);
ALTER TABLE History_0023 SET (fillfactor = 100);
ALTER TABLE History_0023 SET (autovacuum_vacuum_scale_factor = 0.1, autovacuum_vacuum_threshold = 1000, autovacuum_analyze_scale_factor = 0.1, autovacuum_analyze_threshold = 1000);
ALTER TABLE History_0023 SET (parallel_workers = 4);

CREATE TABLE IF NOT EXISTS History_0024 PARTITION OF History FOR VALUES WITH (MODULUS 128, REMAINDER 24);
ALTER TABLE History_0024 SET (fillfactor = 100);
ALTER TABLE History_0024 SET (autovacuum_vacuum_scale_factor = 0.1, autovacuum_vacuum_threshold = 1000, autovacuum_analyze_scale_factor = 0.1, autovacuum_analyze_threshold = 1000);
ALTER TABLE History_0024 SET (parallel_workers = 4);

CREATE TABLE IF NOT EXISTS History_0025 PARTITION OF History FOR VALUES WITH (MODULUS 128, REMAINDER 25);
ALTER TABLE History_0025 SET (fillfactor = 100);
ALTER TABLE History_0025 SET (autovacuum_vacuum_scale_factor = 0.1, autovacuum_vacuum_threshold = 1000, autovacuum_analyze_scale_factor = 0.1, autovacuum_analyze_threshold = 1000);
ALTER TABLE History_0025 SET (parallel_workers = 4);

CREATE TABLE IF NOT EXISTS History_0026 PARTITION OF History FOR VALUES WITH (MODULUS 128, REMAINDER 26);
ALTER TABLE History_0026 SET (fillfactor = 100);
ALTER TABLE History_0026 SET (autovacuum_vacuum_scale_factor = 0.1, autovacuum_vacuum_threshold = 1000, autovacuum_analyze_scale_factor = 0.1, autovacuum_analyze_threshold = 1000);
ALTER TABLE History_0026 SET (parallel_workers = 4);

CREATE TABLE IF NOT EXISTS History_0027 PARTITION OF History FOR VALUES WITH (MODULUS 128, REMAINDER 27);
ALTER TABLE History_0027 SET (fillfactor = 100);
ALTER TABLE History_0027 SET (autovacuum_vacuum_scale_factor = 0.1, autovacuum_vacuum_threshold = 1000, autovacuum_analyze_scale_factor = 0.1, autovacuum_analyze_threshold = 1000);
ALTER TABLE History_0027 SET (parallel_workers = 4);

CREATE TABLE IF NOT EXISTS History_0028 PARTITION OF History FOR VALUES WITH (MODULUS 128, REMAINDER 28);
ALTER TABLE History_0028 SET (fillfactor = 100);
ALTER TABLE History_0028 SET (autovacuum_vacuum_scale_factor = 0.1, autovacuum_vacuum_threshold = 1000, autovacuum_analyze_scale_factor = 0.1, autovacuum_analyze_threshold = 1000);
ALTER TABLE History_0028 SET (parallel_workers = 4);

CREATE TABLE IF NOT EXISTS History_0029 PARTITION OF History FOR VALUES WITH (MODULUS 128, REMAINDER 29);
ALTER TABLE History_0029 SET (fillfactor = 100);
ALTER TABLE History_0029 SET (autovacuum_vacuum_scale_factor = 0.1, autovacuum_vacuum_threshold = 1000, autovacuum_analyze_scale_factor = 0.1, autovacuum_analyze_threshold = 1000);
ALTER TABLE History_0029 SET (parallel_workers = 4);

CREATE TABLE IF NOT EXISTS History_0030 PARTITION OF History FOR VALUES WITH (MODULUS 128, REMAINDER 30);
ALTER TABLE History_0030 SET (fillfactor = 100);
ALTER TABLE History_0030 SET (autovacuum_vacuum_scale_factor = 0.1, autovacuum_vacuum_threshold = 1000, autovacuum_analyze_scale_factor = 0.1, autovacuum_analyze_threshold = 1000);
ALTER TABLE History_0030 SET (parallel_workers = 4);

CREATE TABLE IF NOT EXISTS History_0031 PARTITION OF History FOR VALUES WITH (MODULUS 128, REMAINDER 31);
ALTER TABLE History_0031 SET (fillfactor = 100);
ALTER TABLE History_0031 SET (autovacuum_vacuum_scale_factor = 0.1, autovacuum_vacuum_threshold = 1000, autovacuum_analyze_scale_factor = 0.1, autovacuum_analyze_threshold = 1000);
ALTER TABLE History_0031 SET (parallel_workers = 4);

CREATE TABLE IF NOT EXISTS History_0032 PARTITION OF History FOR VALUES WITH (MODULUS 128, REMAINDER 32);
ALTER TABLE History_0032 SET (fillfactor = 100);
ALTER TABLE History_0032 SET (autovacuum_vacuum_scale_factor = 0.1, autovacuum_vacuum_threshold = 1000, autovacuum_analyze_scale_factor = 0.1, autovacuum_analyze_threshold = 1000);
ALTER TABLE History_0032 SET (parallel_workers = 4);

CREATE TABLE IF NOT EXISTS History_0033 PARTITION OF History FOR VALUES WITH (MODULUS 128, REMAINDER 33);
ALTER TABLE History_0033 SET (fillfactor = 100);
ALTER TABLE History_0033 SET (autovacuum_vacuum_scale_factor = 0.1, autovacuum_vacuum_threshold = 1000, autovacuum_analyze_scale_factor = 0.1, autovacuum_analyze_threshold = 1000);
ALTER TABLE History_0033 SET (parallel_workers = 4);

CREATE TABLE IF NOT EXISTS History_0034 PARTITION OF History FOR VALUES WITH (MODULUS 128, REMAINDER 34);
ALTER TABLE History_0034 SET (fillfactor = 100);
ALTER TABLE History_0034 SET (autovacuum_vacuum_scale_factor = 0.1, autovacuum_vacuum_threshold = 1000, autovacuum_analyze_scale_factor = 0.1, autovacuum_analyze_threshold = 1000);
ALTER TABLE History_0034 SET (parallel_workers = 4);

CREATE TABLE IF NOT EXISTS History_0035 PARTITION OF History FOR VALUES WITH (MODULUS 128, REMAINDER 35);
ALTER TABLE History_0035 SET (fillfactor = 100);
ALTER TABLE History_0035 SET (autovacuum_vacuum_scale_factor = 0.1, autovacuum_vacuum_threshold = 1000, autovacuum_analyze_scale_factor = 0.1, autovacuum_analyze_threshold = 1000);
ALTER TABLE History_0035 SET (parallel_workers = 4);

CREATE TABLE IF NOT EXISTS History_0036 PARTITION OF History FOR VALUES WITH (MODULUS 128, REMAINDER 36);
ALTER TABLE History_0036 SET (fillfactor = 100);
ALTER TABLE History_0036 SET (autovacuum_vacuum_scale_factor = 0.1, autovacuum_vacuum_threshold = 1000, autovacuum_analyze_scale_factor = 0.1, autovacuum_analyze_threshold = 1000);
ALTER TABLE History_0036 SET (parallel_workers = 4);

CREATE TABLE IF NOT EXISTS History_0037 PARTITION OF History FOR VALUES WITH (MODULUS 128, REMAINDER 37);
ALTER TABLE History_0037 SET (fillfactor = 100);
ALTER TABLE History_0037 SET (autovacuum_vacuum_scale_factor = 0.1, autovacuum_vacuum_threshold = 1000, autovacuum_analyze_scale_factor = 0.1, autovacuum_analyze_threshold = 1000);
ALTER TABLE History_0037 SET (parallel_workers = 4);

CREATE TABLE IF NOT EXISTS History_0038 PARTITION OF History FOR VALUES WITH (MODULUS 128, REMAINDER 38);
ALTER TABLE History_0038 SET (fillfactor = 100);
ALTER TABLE History_0038 SET (autovacuum_vacuum_scale_factor = 0.1, autovacuum_vacuum_threshold = 1000, autovacuum_analyze_scale_factor = 0.1, autovacuum_analyze_threshold = 1000);
ALTER TABLE History_0038 SET (parallel_workers = 4);

CREATE TABLE IF NOT EXISTS History_0039 PARTITION OF History FOR VALUES WITH (MODULUS 128, REMAINDER 39);
ALTER TABLE History_0039 SET (fillfactor = 100);
ALTER TABLE History_0039 SET (autovacuum_vacuum_scale_factor = 0.1, autovacuum_vacuum_threshold = 1000, autovacuum_analyze_scale_factor = 0.1, autovacuum_analyze_threshold = 1000);
ALTER TABLE History_0039 SET (parallel_workers = 4);

CREATE TABLE IF NOT EXISTS History_0040 PARTITION OF History FOR VALUES WITH (MODULUS 128, REMAINDER 40);
ALTER TABLE History_0040 SET (fillfactor = 100);
ALTER TABLE History_0040 SET (autovacuum_vacuum_scale_factor = 0.1, autovacuum_vacuum_threshold = 1000, autovacuum_analyze_scale_factor = 0.1, autovacuum_analyze_threshold = 1000);
ALTER TABLE History_0040 SET (parallel_workers = 4);

CREATE TABLE IF NOT EXISTS History_0041 PARTITION OF History FOR VALUES WITH (MODULUS 128, REMAINDER 41);
ALTER TABLE History_0041 SET (fillfactor = 100);
ALTER TABLE History_0041 SET (autovacuum_vacuum_scale_factor = 0.1, autovacuum_vacuum_threshold = 1000, autovacuum_analyze_scale_factor = 0.1, autovacuum_analyze_threshold = 1000);
ALTER TABLE History_0041 SET (parallel_workers = 4);

CREATE TABLE IF NOT EXISTS History_0042 PARTITION OF History FOR VALUES WITH (MODULUS 128, REMAINDER 42);
ALTER TABLE History_0042 SET (fillfactor = 100);
ALTER TABLE History_0042 SET (autovacuum_vacuum_scale_factor = 0.1, autovacuum_vacuum_threshold = 1000, autovacuum_analyze_scale_factor = 0.1, autovacuum_analyze_threshold = 1000);
ALTER TABLE History_0042 SET (parallel_workers = 4);

CREATE TABLE IF NOT EXISTS History_0043 PARTITION OF History FOR VALUES WITH (MODULUS 128, REMAINDER 43);
ALTER TABLE History_0043 SET (fillfactor = 100);
ALTER TABLE History_0043 SET (autovacuum_vacuum_scale_factor = 0.1, autovacuum_vacuum_threshold = 1000, autovacuum_analyze_scale_factor = 0.1, autovacuum_analyze_threshold = 1000);
ALTER TABLE History_0043 SET (parallel_workers = 4);

CREATE TABLE IF NOT EXISTS History_0044 PARTITION OF History FOR VALUES WITH (MODULUS 128, REMAINDER 44);
ALTER TABLE History_0044 SET (fillfactor = 100);
ALTER TABLE History_0044 SET (autovacuum_vacuum_scale_factor = 0.1, autovacuum_vacuum_threshold = 1000, autovacuum_analyze_scale_factor = 0.1, autovacuum_analyze_threshold = 1000);
ALTER TABLE History_0044 SET (parallel_workers = 4);

CREATE TABLE IF NOT EXISTS History_0045 PARTITION OF History FOR VALUES WITH (MODULUS 128, REMAINDER 45);
ALTER TABLE History_0045 SET (fillfactor = 100);
ALTER TABLE History_0045 SET (autovacuum_vacuum_scale_factor = 0.1, autovacuum_vacuum_threshold = 1000, autovacuum_analyze_scale_factor = 0.1, autovacuum_analyze_threshold = 1000);
ALTER TABLE History_0045 SET (parallel_workers = 4);

CREATE TABLE IF NOT EXISTS History_0046 PARTITION OF History FOR VALUES WITH (MODULUS 128, REMAINDER 46);
ALTER TABLE History_0046 SET (fillfactor = 100);
ALTER TABLE History_0046 SET (autovacuum_vacuum_scale_factor = 0.1, autovacuum_vacuum_threshold = 1000, autovacuum_analyze_scale_factor = 0.1, autovacuum_analyze_threshold = 1000);
ALTER TABLE History_0046 SET (parallel_workers = 4);

CREATE TABLE IF NOT EXISTS History_0047 PARTITION OF History FOR VALUES WITH (MODULUS 128, REMAINDER 47);
ALTER TABLE History_0047 SET (fillfactor = 100);
ALTER TABLE History_0047 SET (autovacuum_vacuum_scale_factor = 0.1, autovacuum_vacuum_threshold = 1000, autovacuum_analyze_scale_factor = 0.1, autovacuum_analyze_threshold = 1000);
ALTER TABLE History_0047 SET (parallel_workers = 4);

CREATE TABLE IF NOT EXISTS History_0048 PARTITION OF History FOR VALUES WITH (MODULUS 128, REMAINDER 48);
ALTER TABLE History_0048 SET (fillfactor = 100);
ALTER TABLE History_0048 SET (autovacuum_vacuum_scale_factor = 0.1, autovacuum_vacuum_threshold = 1000, autovacuum_analyze_scale_factor = 0.1, autovacuum_analyze_threshold = 1000);
ALTER TABLE History_0048 SET (parallel_workers = 4);

CREATE TABLE IF NOT EXISTS History_0049 PARTITION OF History FOR VALUES WITH (MODULUS 128, REMAINDER 49);
ALTER TABLE History_0049 SET (fillfactor = 100);
ALTER TABLE History_0049 SET (autovacuum_vacuum_scale_factor = 0.1, autovacuum_vacuum_threshold = 1000, autovacuum_analyze_scale_factor = 0.1, autovacuum_analyze_threshold = 1000);
ALTER TABLE History_0049 SET (parallel_workers = 4);

CREATE TABLE IF NOT EXISTS History_0050 PARTITION OF History FOR VALUES WITH (MODULUS 128, REMAINDER 50);
ALTER TABLE History_0050 SET (fillfactor = 100);
ALTER TABLE History_0050 SET (autovacuum_vacuum_scale_factor = 0.1, autovacuum_vacuum_threshold = 1000, autovacuum_analyze_scale_factor = 0.1, autovacuum_analyze_threshold = 1000);
ALTER TABLE History_0050 SET (parallel_workers = 4);

CREATE TABLE IF NOT EXISTS History_0051 PARTITION OF History FOR VALUES WITH (MODULUS 128, REMAINDER 51);
ALTER TABLE History_0051 SET (fillfactor = 100);
ALTER TABLE History_0051 SET (autovacuum_vacuum_scale_factor = 0.1, autovacuum_vacuum_threshold = 1000, autovacuum_analyze_scale_factor = 0.1, autovacuum_analyze_threshold = 1000);
ALTER TABLE History_0051 SET (parallel_workers = 4);

CREATE TABLE IF NOT EXISTS History_0052 PARTITION OF History FOR VALUES WITH (MODULUS 128, REMAINDER 52);
ALTER TABLE History_0052 SET (fillfactor = 100);
ALTER TABLE History_0052 SET (autovacuum_vacuum_scale_factor = 0.1, autovacuum_vacuum_threshold = 1000, autovacuum_analyze_scale_factor = 0.1, autovacuum_analyze_threshold = 1000);
ALTER TABLE History_0052 SET (parallel_workers = 4);

CREATE TABLE IF NOT EXISTS History_0053 PARTITION OF History FOR VALUES WITH (MODULUS 128, REMAINDER 53);
ALTER TABLE History_0053 SET (fillfactor = 100);
ALTER TABLE History_0053 SET (autovacuum_vacuum_scale_factor = 0.1, autovacuum_vacuum_threshold = 1000, autovacuum_analyze_scale_factor = 0.1, autovacuum_analyze_threshold = 1000);
ALTER TABLE History_0053 SET (parallel_workers = 4);

CREATE TABLE IF NOT EXISTS History_0054 PARTITION OF History FOR VALUES WITH (MODULUS 128, REMAINDER 54);
ALTER TABLE History_0054 SET (fillfactor = 100);
ALTER TABLE History_0054 SET (autovacuum_vacuum_scale_factor = 0.1, autovacuum_vacuum_threshold = 1000, autovacuum_analyze_scale_factor = 0.1, autovacuum_analyze_threshold = 1000);
ALTER TABLE History_0054 SET (parallel_workers = 4);

CREATE TABLE IF NOT EXISTS History_0055 PARTITION OF History FOR VALUES WITH (MODULUS 128, REMAINDER 55);
ALTER TABLE History_0055 SET (fillfactor = 100);
ALTER TABLE History_0055 SET (autovacuum_vacuum_scale_factor = 0.1, autovacuum_vacuum_threshold = 1000, autovacuum_analyze_scale_factor = 0.1, autovacuum_analyze_threshold = 1000);
ALTER TABLE History_0055 SET (parallel_workers = 4);

CREATE TABLE IF NOT EXISTS History_0056 PARTITION OF History FOR VALUES WITH (MODULUS 128, REMAINDER 56);
ALTER TABLE History_0056 SET (fillfactor = 100);
ALTER TABLE History_0056 SET (autovacuum_vacuum_scale_factor = 0.1, autovacuum_vacuum_threshold = 1000, autovacuum_analyze_scale_factor = 0.1, autovacuum_analyze_threshold = 1000);
ALTER TABLE History_0056 SET (parallel_workers = 4);

CREATE TABLE IF NOT EXISTS History_0057 PARTITION OF History FOR VALUES WITH (MODULUS 128, REMAINDER 57);
ALTER TABLE History_0057 SET (fillfactor = 100);
ALTER TABLE History_0057 SET (autovacuum_vacuum_scale_factor = 0.1, autovacuum_vacuum_threshold = 1000, autovacuum_analyze_scale_factor = 0.1, autovacuum_analyze_threshold = 1000);
ALTER TABLE History_0057 SET (parallel_workers = 4);

CREATE TABLE IF NOT EXISTS History_0058 PARTITION OF History FOR VALUES WITH (MODULUS 128, REMAINDER 58);
ALTER TABLE History_0058 SET (fillfactor = 100);
ALTER TABLE History_0058 SET (autovacuum_vacuum_scale_factor = 0.1, autovacuum_vacuum_threshold = 1000, autovacuum_analyze_scale_factor = 0.1, autovacuum_analyze_threshold = 1000);
ALTER TABLE History_0058 SET (parallel_workers = 4);

CREATE TABLE IF NOT EXISTS History_0059 PARTITION OF History FOR VALUES WITH (MODULUS 128, REMAINDER 59);
ALTER TABLE History_0059 SET (fillfactor = 100);
ALTER TABLE History_0059 SET (autovacuum_vacuum_scale_factor = 0.1, autovacuum_vacuum_threshold = 1000, autovacuum_analyze_scale_factor = 0.1, autovacuum_analyze_threshold = 1000);
ALTER TABLE History_0059 SET (parallel_workers = 4);

CREATE TABLE IF NOT EXISTS History_0060 PARTITION OF History FOR VALUES WITH (MODULUS 128, REMAINDER 60);
ALTER TABLE History_0060 SET (fillfactor = 100);
ALTER TABLE History_0060 SET (autovacuum_vacuum_scale_factor = 0.1, autovacuum_vacuum_threshold = 1000, autovacuum_analyze_scale_factor = 0.1, autovacuum_analyze_threshold = 1000);
ALTER TABLE History_0060 SET (parallel_workers = 4);

CREATE TABLE IF NOT EXISTS History_0061 PARTITION OF History FOR VALUES WITH (MODULUS 128, REMAINDER 61);
ALTER TABLE History_0061 SET (fillfactor = 100);
ALTER TABLE History_0061 SET (autovacuum_vacuum_scale_factor = 0.1, autovacuum_vacuum_threshold = 1000, autovacuum_analyze_scale_factor = 0.1, autovacuum_analyze_threshold = 1000);
ALTER TABLE History_0061 SET (parallel_workers = 4);

CREATE TABLE IF NOT EXISTS History_0062 PARTITION OF History FOR VALUES WITH (MODULUS 128, REMAINDER 62);
ALTER TABLE History_0062 SET (fillfactor = 100);
ALTER TABLE History_0062 SET (autovacuum_vacuum_scale_factor = 0.1, autovacuum_vacuum_threshold = 1000, autovacuum_analyze_scale_factor = 0.1, autovacuum_analyze_threshold = 1000);
ALTER TABLE History_0062 SET (parallel_workers = 4);

CREATE TABLE IF NOT EXISTS History_0063 PARTITION OF History FOR VALUES WITH (MODULUS 128, REMAINDER 63);
ALTER TABLE History_0063 SET (fillfactor = 100);
ALTER TABLE History_0063 SET (autovacuum_vacuum_scale_factor = 0.1, autovacuum_vacuum_threshold = 1000, autovacuum_analyze_scale_factor = 0.1, autovacuum_analyze_threshold = 1000);
ALTER TABLE History_0063 SET (parallel_workers = 4);

CREATE TABLE IF NOT EXISTS History_0064 PARTITION OF History FOR VALUES WITH (MODULUS 128, REMAINDER 64);
ALTER TABLE History_0064 SET (fillfactor = 100);
ALTER TABLE History_0064 SET (autovacuum_vacuum_scale_factor = 0.1, autovacuum_vacuum_threshold = 1000, autovacuum_analyze_scale_factor = 0.1, autovacuum_analyze_threshold = 1000);
ALTER TABLE History_0064 SET (parallel_workers = 4);

CREATE TABLE IF NOT EXISTS History_0065 PARTITION OF History FOR VALUES WITH (MODULUS 128, REMAINDER 65);
ALTER TABLE History_0065 SET (fillfactor = 100);
ALTER TABLE History_0065 SET (autovacuum_vacuum_scale_factor = 0.1, autovacuum_vacuum_threshold = 1000, autovacuum_analyze_scale_factor = 0.1, autovacuum_analyze_threshold = 1000);
ALTER TABLE History_0065 SET (parallel_workers = 4);

CREATE TABLE IF NOT EXISTS History_0066 PARTITION OF History FOR VALUES WITH (MODULUS 128, REMAINDER 66);
ALTER TABLE History_0066 SET (fillfactor = 100);
ALTER TABLE History_0066 SET (autovacuum_vacuum_scale_factor = 0.1, autovacuum_vacuum_threshold = 1000, autovacuum_analyze_scale_factor = 0.1, autovacuum_analyze_threshold = 1000);
ALTER TABLE History_0066 SET (parallel_workers = 4);

CREATE TABLE IF NOT EXISTS History_0067 PARTITION OF History FOR VALUES WITH (MODULUS 128, REMAINDER 67);
ALTER TABLE History_0067 SET (fillfactor = 100);
ALTER TABLE History_0067 SET (autovacuum_vacuum_scale_factor = 0.1, autovacuum_vacuum_threshold = 1000, autovacuum_analyze_scale_factor = 0.1, autovacuum_analyze_threshold = 1000);
ALTER TABLE History_0067 SET (parallel_workers = 4);

CREATE TABLE IF NOT EXISTS History_0068 PARTITION OF History FOR VALUES WITH (MODULUS 128, REMAINDER 68);
ALTER TABLE History_0068 SET (fillfactor = 100);
ALTER TABLE History_0068 SET (autovacuum_vacuum_scale_factor = 0.1, autovacuum_vacuum_threshold = 1000, autovacuum_analyze_scale_factor = 0.1, autovacuum_analyze_threshold = 1000);
ALTER TABLE History_0068 SET (parallel_workers = 4);

CREATE TABLE IF NOT EXISTS History_0069 PARTITION OF History FOR VALUES WITH (MODULUS 128, REMAINDER 69);
ALTER TABLE History_0069 SET (fillfactor = 100);
ALTER TABLE History_0069 SET (autovacuum_vacuum_scale_factor = 0.1, autovacuum_vacuum_threshold = 1000, autovacuum_analyze_scale_factor = 0.1, autovacuum_analyze_threshold = 1000);
ALTER TABLE History_0069 SET (parallel_workers = 4);

CREATE TABLE IF NOT EXISTS History_0070 PARTITION OF History FOR VALUES WITH (MODULUS 128, REMAINDER 70);
ALTER TABLE History_0070 SET (fillfactor = 100);
ALTER TABLE History_0070 SET (autovacuum_vacuum_scale_factor = 0.1, autovacuum_vacuum_threshold = 1000, autovacuum_analyze_scale_factor = 0.1, autovacuum_analyze_threshold = 1000);
ALTER TABLE History_0070 SET (parallel_workers = 4);

CREATE TABLE IF NOT EXISTS History_0071 PARTITION OF History FOR VALUES WITH (MODULUS 128, REMAINDER 71);
ALTER TABLE History_0071 SET (fillfactor = 100);
ALTER TABLE History_0071 SET (autovacuum_vacuum_scale_factor = 0.1, autovacuum_vacuum_threshold = 1000, autovacuum_analyze_scale_factor = 0.1, autovacuum_analyze_threshold = 1000);
ALTER TABLE History_0071 SET (parallel_workers = 4);

CREATE TABLE IF NOT EXISTS History_0072 PARTITION OF History FOR VALUES WITH (MODULUS 128, REMAINDER 72);
ALTER TABLE History_0072 SET (fillfactor = 100);
ALTER TABLE History_0072 SET (autovacuum_vacuum_scale_factor = 0.1, autovacuum_vacuum_threshold = 1000, autovacuum_analyze_scale_factor = 0.1, autovacuum_analyze_threshold = 1000);
ALTER TABLE History_0072 SET (parallel_workers = 4);

CREATE TABLE IF NOT EXISTS History_0073 PARTITION OF History FOR VALUES WITH (MODULUS 128, REMAINDER 73);
ALTER TABLE History_0073 SET (fillfactor = 100);
ALTER TABLE History_0073 SET (autovacuum_vacuum_scale_factor = 0.1, autovacuum_vacuum_threshold = 1000, autovacuum_analyze_scale_factor = 0.1, autovacuum_analyze_threshold = 1000);
ALTER TABLE History_0073 SET (parallel_workers = 4);

CREATE TABLE IF NOT EXISTS History_0074 PARTITION OF History FOR VALUES WITH (MODULUS 128, REMAINDER 74);
ALTER TABLE History_0074 SET (fillfactor = 100);
ALTER TABLE History_0074 SET (autovacuum_vacuum_scale_factor = 0.1, autovacuum_vacuum_threshold = 1000, autovacuum_analyze_scale_factor = 0.1, autovacuum_analyze_threshold = 1000);
ALTER TABLE History_0074 SET (parallel_workers = 4);

CREATE TABLE IF NOT EXISTS History_0075 PARTITION OF History FOR VALUES WITH (MODULUS 128, REMAINDER 75);
ALTER TABLE History_0075 SET (fillfactor = 100);
ALTER TABLE History_0075 SET (autovacuum_vacuum_scale_factor = 0.1, autovacuum_vacuum_threshold = 1000, autovacuum_analyze_scale_factor = 0.1, autovacuum_analyze_threshold = 1000);
ALTER TABLE History_0075 SET (parallel_workers = 4);

CREATE TABLE IF NOT EXISTS History_0076 PARTITION OF History FOR VALUES WITH (MODULUS 128, REMAINDER 76);
ALTER TABLE History_0076 SET (fillfactor = 100);
ALTER TABLE History_0076 SET (autovacuum_vacuum_scale_factor = 0.1, autovacuum_vacuum_threshold = 1000, autovacuum_analyze_scale_factor = 0.1, autovacuum_analyze_threshold = 1000);
ALTER TABLE History_0076 SET (parallel_workers = 4);

CREATE TABLE IF NOT EXISTS History_0077 PARTITION OF History FOR VALUES WITH (MODULUS 128, REMAINDER 77);
ALTER TABLE History_0077 SET (fillfactor = 100);
ALTER TABLE History_0077 SET (autovacuum_vacuum_scale_factor = 0.1, autovacuum_vacuum_threshold = 1000, autovacuum_analyze_scale_factor = 0.1, autovacuum_analyze_threshold = 1000);
ALTER TABLE History_0077 SET (parallel_workers = 4);

CREATE TABLE IF NOT EXISTS History_0078 PARTITION OF History FOR VALUES WITH (MODULUS 128, REMAINDER 78);
ALTER TABLE History_0078 SET (fillfactor = 100);
ALTER TABLE History_0078 SET (autovacuum_vacuum_scale_factor = 0.1, autovacuum_vacuum_threshold = 1000, autovacuum_analyze_scale_factor = 0.1, autovacuum_analyze_threshold = 1000);
ALTER TABLE History_0078 SET (parallel_workers = 4);

CREATE TABLE IF NOT EXISTS History_0079 PARTITION OF History FOR VALUES WITH (MODULUS 128, REMAINDER 79);
ALTER TABLE History_0079 SET (fillfactor = 100);
ALTER TABLE History_0079 SET (autovacuum_vacuum_scale_factor = 0.1, autovacuum_vacuum_threshold = 1000, autovacuum_analyze_scale_factor = 0.1, autovacuum_analyze_threshold = 1000);
ALTER TABLE History_0079 SET (parallel_workers = 4);

CREATE TABLE IF NOT EXISTS History_0080 PARTITION OF History FOR VALUES WITH (MODULUS 128, REMAINDER 80);
ALTER TABLE History_0080 SET (fillfactor = 100);
ALTER TABLE History_0080 SET (autovacuum_vacuum_scale_factor = 0.1, autovacuum_vacuum_threshold = 1000, autovacuum_analyze_scale_factor = 0.1, autovacuum_analyze_threshold = 1000);
ALTER TABLE History_0080 SET (parallel_workers = 4);

CREATE TABLE IF NOT EXISTS History_0081 PARTITION OF History FOR VALUES WITH (MODULUS 128, REMAINDER 81);
ALTER TABLE History_0081 SET (fillfactor = 100);
ALTER TABLE History_0081 SET (autovacuum_vacuum_scale_factor = 0.1, autovacuum_vacuum_threshold = 1000, autovacuum_analyze_scale_factor = 0.1, autovacuum_analyze_threshold = 1000);
ALTER TABLE History_0081 SET (parallel_workers = 4);

CREATE TABLE IF NOT EXISTS History_0082 PARTITION OF History FOR VALUES WITH (MODULUS 128, REMAINDER 82);
ALTER TABLE History_0082 SET (fillfactor = 100);
ALTER TABLE History_0082 SET (autovacuum_vacuum_scale_factor = 0.1, autovacuum_vacuum_threshold = 1000, autovacuum_analyze_scale_factor = 0.1, autovacuum_analyze_threshold = 1000);
ALTER TABLE History_0082 SET (parallel_workers = 4);

CREATE TABLE IF NOT EXISTS History_0083 PARTITION OF History FOR VALUES WITH (MODULUS 128, REMAINDER 83);
ALTER TABLE History_0083 SET (fillfactor = 100);
ALTER TABLE History_0083 SET (autovacuum_vacuum_scale_factor = 0.1, autovacuum_vacuum_threshold = 1000, autovacuum_analyze_scale_factor = 0.1, autovacuum_analyze_threshold = 1000);
ALTER TABLE History_0083 SET (parallel_workers = 4);

CREATE TABLE IF NOT EXISTS History_0084 PARTITION OF History FOR VALUES WITH (MODULUS 128, REMAINDER 84);
ALTER TABLE History_0084 SET (fillfactor = 100);
ALTER TABLE History_0084 SET (autovacuum_vacuum_scale_factor = 0.1, autovacuum_vacuum_threshold = 1000, autovacuum_analyze_scale_factor = 0.1, autovacuum_analyze_threshold = 1000);
ALTER TABLE History_0084 SET (parallel_workers = 4);

CREATE TABLE IF NOT EXISTS History_0085 PARTITION OF History FOR VALUES WITH (MODULUS 128, REMAINDER 85);
ALTER TABLE History_0085 SET (fillfactor = 100);
ALTER TABLE History_0085 SET (autovacuum_vacuum_scale_factor = 0.1, autovacuum_vacuum_threshold = 1000, autovacuum_analyze_scale_factor = 0.1, autovacuum_analyze_threshold = 1000);
ALTER TABLE History_0085 SET (parallel_workers = 4);

CREATE TABLE IF NOT EXISTS History_0086 PARTITION OF History FOR VALUES WITH (MODULUS 128, REMAINDER 86);
ALTER TABLE History_0086 SET (fillfactor = 100);
ALTER TABLE History_0086 SET (autovacuum_vacuum_scale_factor = 0.1, autovacuum_vacuum_threshold = 1000, autovacuum_analyze_scale_factor = 0.1, autovacuum_analyze_threshold = 1000);
ALTER TABLE History_0086 SET (parallel_workers = 4);

CREATE TABLE IF NOT EXISTS History_0087 PARTITION OF History FOR VALUES WITH (MODULUS 128, REMAINDER 87);
ALTER TABLE History_0087 SET (fillfactor = 100);
ALTER TABLE History_0087 SET (autovacuum_vacuum_scale_factor = 0.1, autovacuum_vacuum_threshold = 1000, autovacuum_analyze_scale_factor = 0.1, autovacuum_analyze_threshold = 1000);
ALTER TABLE History_0087 SET (parallel_workers = 4);

CREATE TABLE IF NOT EXISTS History_0088 PARTITION OF History FOR VALUES WITH (MODULUS 128, REMAINDER 88);
ALTER TABLE History_0088 SET (fillfactor = 100);
ALTER TABLE History_0088 SET (autovacuum_vacuum_scale_factor = 0.1, autovacuum_vacuum_threshold = 1000, autovacuum_analyze_scale_factor = 0.1, autovacuum_analyze_threshold = 1000);
ALTER TABLE History_0088 SET (parallel_workers = 4);

CREATE TABLE IF NOT EXISTS History_0089 PARTITION OF History FOR VALUES WITH (MODULUS 128, REMAINDER 89);
ALTER TABLE History_0089 SET (fillfactor = 100);
ALTER TABLE History_0089 SET (autovacuum_vacuum_scale_factor = 0.1, autovacuum_vacuum_threshold = 1000, autovacuum_analyze_scale_factor = 0.1, autovacuum_analyze_threshold = 1000);
ALTER TABLE History_0089 SET (parallel_workers = 4);

CREATE TABLE IF NOT EXISTS History_0090 PARTITION OF History FOR VALUES WITH (MODULUS 128, REMAINDER 90);
ALTER TABLE History_0090 SET (fillfactor = 100);
ALTER TABLE History_0090 SET (autovacuum_vacuum_scale_factor = 0.1, autovacuum_vacuum_threshold = 1000, autovacuum_analyze_scale_factor = 0.1, autovacuum_analyze_threshold = 1000);
ALTER TABLE History_0090 SET (parallel_workers = 4);

CREATE TABLE IF NOT EXISTS History_0091 PARTITION OF History FOR VALUES WITH (MODULUS 128, REMAINDER 91);
ALTER TABLE History_0091 SET (fillfactor = 100);
ALTER TABLE History_0091 SET (autovacuum_vacuum_scale_factor = 0.1, autovacuum_vacuum_threshold = 1000, autovacuum_analyze_scale_factor = 0.1, autovacuum_analyze_threshold = 1000);
ALTER TABLE History_0091 SET (parallel_workers = 4);

CREATE TABLE IF NOT EXISTS History_0092 PARTITION OF History FOR VALUES WITH (MODULUS 128, REMAINDER 92);
ALTER TABLE History_0092 SET (fillfactor = 100);
ALTER TABLE History_0092 SET (autovacuum_vacuum_scale_factor = 0.1, autovacuum_vacuum_threshold = 1000, autovacuum_analyze_scale_factor = 0.1, autovacuum_analyze_threshold = 1000);
ALTER TABLE History_0092 SET (parallel_workers = 4);

CREATE TABLE IF NOT EXISTS History_0093 PARTITION OF History FOR VALUES WITH (MODULUS 128, REMAINDER 93);
ALTER TABLE History_0093 SET (fillfactor = 100);
ALTER TABLE History_0093 SET (autovacuum_vacuum_scale_factor = 0.1, autovacuum_vacuum_threshold = 1000, autovacuum_analyze_scale_factor = 0.1, autovacuum_analyze_threshold = 1000);
ALTER TABLE History_0093 SET (parallel_workers = 4);

CREATE TABLE IF NOT EXISTS History_0094 PARTITION OF History FOR VALUES WITH (MODULUS 128, REMAINDER 94);
ALTER TABLE History_0094 SET (fillfactor = 100);
ALTER TABLE History_0094 SET (autovacuum_vacuum_scale_factor = 0.1, autovacuum_vacuum_threshold = 1000, autovacuum_analyze_scale_factor = 0.1, autovacuum_analyze_threshold = 1000);
ALTER TABLE History_0094 SET (parallel_workers = 4);

CREATE TABLE IF NOT EXISTS History_0095 PARTITION OF History FOR VALUES WITH (MODULUS 128, REMAINDER 95);
ALTER TABLE History_0095 SET (fillfactor = 100);
ALTER TABLE History_0095 SET (autovacuum_vacuum_scale_factor = 0.1, autovacuum_vacuum_threshold = 1000, autovacuum_analyze_scale_factor = 0.1, autovacuum_analyze_threshold = 1000);
ALTER TABLE History_0095 SET (parallel_workers = 4);

CREATE TABLE IF NOT EXISTS History_0096 PARTITION OF History FOR VALUES WITH (MODULUS 128, REMAINDER 96);
ALTER TABLE History_0096 SET (fillfactor = 100);
ALTER TABLE History_0096 SET (autovacuum_vacuum_scale_factor = 0.1, autovacuum_vacuum_threshold = 1000, autovacuum_analyze_scale_factor = 0.1, autovacuum_analyze_threshold = 1000);
ALTER TABLE History_0096 SET (parallel_workers = 4);

CREATE TABLE IF NOT EXISTS History_0097 PARTITION OF History FOR VALUES WITH (MODULUS 128, REMAINDER 97);
ALTER TABLE History_0097 SET (fillfactor = 100);
ALTER TABLE History_0097 SET (autovacuum_vacuum_scale_factor = 0.1, autovacuum_vacuum_threshold = 1000, autovacuum_analyze_scale_factor = 0.1, autovacuum_analyze_threshold = 1000);
ALTER TABLE History_0097 SET (parallel_workers = 4);

CREATE TABLE IF NOT EXISTS History_0098 PARTITION OF History FOR VALUES WITH (MODULUS 128, REMAINDER 98);
ALTER TABLE History_0098 SET (fillfactor = 100);
ALTER TABLE History_0098 SET (autovacuum_vacuum_scale_factor = 0.1, autovacuum_vacuum_threshold = 1000, autovacuum_analyze_scale_factor = 0.1, autovacuum_analyze_threshold = 1000);
ALTER TABLE History_0098 SET (parallel_workers = 4);

CREATE TABLE IF NOT EXISTS History_0099 PARTITION OF History FOR VALUES WITH (MODULUS 128, REMAINDER 99);
ALTER TABLE History_0099 SET (fillfactor = 100);
ALTER TABLE History_0099 SET (autovacuum_vacuum_scale_factor = 0.1, autovacuum_vacuum_threshold = 1000, autovacuum_analyze_scale_factor = 0.1, autovacuum_analyze_threshold = 1000);
ALTER TABLE History_0099 SET (parallel_workers = 4);

CREATE TABLE IF NOT EXISTS History_0100 PARTITION OF History FOR VALUES WITH (MODULUS 128, REMAINDER 100);
ALTER TABLE History_0100 SET (fillfactor = 100);
ALTER TABLE History_0100 SET (autovacuum_vacuum_scale_factor = 0.1, autovacuum_vacuum_threshold = 1000, autovacuum_analyze_scale_factor = 0.1, autovacuum_analyze_threshold = 1000);
ALTER TABLE History_0100 SET (parallel_workers = 4);

CREATE TABLE IF NOT EXISTS History_0101 PARTITION OF History FOR VALUES WITH (MODULUS 128, REMAINDER 101);
ALTER TABLE History_0101 SET (fillfactor = 100);
ALTER TABLE History_0101 SET (autovacuum_vacuum_scale_factor = 0.1, autovacuum_vacuum_threshold = 1000, autovacuum_analyze_scale_factor = 0.1, autovacuum_analyze_threshold = 1000);
ALTER TABLE History_0101 SET (parallel_workers = 4);

CREATE TABLE IF NOT EXISTS History_0102 PARTITION OF History FOR VALUES WITH (MODULUS 128, REMAINDER 102);
ALTER TABLE History_0102 SET (fillfactor = 100);
ALTER TABLE History_0102 SET (autovacuum_vacuum_scale_factor = 0.1, autovacuum_vacuum_threshold = 1000, autovacuum_analyze_scale_factor = 0.1, autovacuum_analyze_threshold = 1000);
ALTER TABLE History_0102 SET (parallel_workers = 4);

CREATE TABLE IF NOT EXISTS History_0103 PARTITION OF History FOR VALUES WITH (MODULUS 128, REMAINDER 103);
ALTER TABLE History_0103 SET (fillfactor = 100);
ALTER TABLE History_0103 SET (autovacuum_vacuum_scale_factor = 0.1, autovacuum_vacuum_threshold = 1000, autovacuum_analyze_scale_factor = 0.1, autovacuum_analyze_threshold = 1000);
ALTER TABLE History_0103 SET (parallel_workers = 4);

CREATE TABLE IF NOT EXISTS History_0104 PARTITION OF History FOR VALUES WITH (MODULUS 128, REMAINDER 104);
ALTER TABLE History_0104 SET (fillfactor = 100);
ALTER TABLE History_0104 SET (autovacuum_vacuum_scale_factor = 0.1, autovacuum_vacuum_threshold = 1000, autovacuum_analyze_scale_factor = 0.1, autovacuum_analyze_threshold = 1000);
ALTER TABLE History_0104 SET (parallel_workers = 4);

CREATE TABLE IF NOT EXISTS History_0105 PARTITION OF History FOR VALUES WITH (MODULUS 128, REMAINDER 105);
ALTER TABLE History_0105 SET (fillfactor = 100);
ALTER TABLE History_0105 SET (autovacuum_vacuum_scale_factor = 0.1, autovacuum_vacuum_threshold = 1000, autovacuum_analyze_scale_factor = 0.1, autovacuum_analyze_threshold = 1000);
ALTER TABLE History_0105 SET (parallel_workers = 4);

CREATE TABLE IF NOT EXISTS History_0106 PARTITION OF History FOR VALUES WITH (MODULUS 128, REMAINDER 106);
ALTER TABLE History_0106 SET (fillfactor = 100);
ALTER TABLE History_0106 SET (autovacuum_vacuum_scale_factor = 0.1, autovacuum_vacuum_threshold = 1000, autovacuum_analyze_scale_factor = 0.1, autovacuum_analyze_threshold = 1000);
ALTER TABLE History_0106 SET (parallel_workers = 4);

CREATE TABLE IF NOT EXISTS History_0107 PARTITION OF History FOR VALUES WITH (MODULUS 128, REMAINDER 107);
ALTER TABLE History_0107 SET (fillfactor = 100);
ALTER TABLE History_0107 SET (autovacuum_vacuum_scale_factor = 0.1, autovacuum_vacuum_threshold = 1000, autovacuum_analyze_scale_factor = 0.1, autovacuum_analyze_threshold = 1000);
ALTER TABLE History_0107 SET (parallel_workers = 4);

CREATE TABLE IF NOT EXISTS History_0108 PARTITION OF History FOR VALUES WITH (MODULUS 128, REMAINDER 108);
ALTER TABLE History_0108 SET (fillfactor = 100);
ALTER TABLE History_0108 SET (autovacuum_vacuum_scale_factor = 0.1, autovacuum_vacuum_threshold = 1000, autovacuum_analyze_scale_factor = 0.1, autovacuum_analyze_threshold = 1000);
ALTER TABLE History_0108 SET (parallel_workers = 4);

CREATE TABLE IF NOT EXISTS History_0109 PARTITION OF History FOR VALUES WITH (MODULUS 128, REMAINDER 109);
ALTER TABLE History_0109 SET (fillfactor = 100);
ALTER TABLE History_0109 SET (autovacuum_vacuum_scale_factor = 0.1, autovacuum_vacuum_threshold = 1000, autovacuum_analyze_scale_factor = 0.1, autovacuum_analyze_threshold = 1000);
ALTER TABLE History_0109 SET (parallel_workers = 4);

CREATE TABLE IF NOT EXISTS History_0110 PARTITION OF History FOR VALUES WITH (MODULUS 128, REMAINDER 110);
ALTER TABLE History_0110 SET (fillfactor = 100);
ALTER TABLE History_0110 SET (autovacuum_vacuum_scale_factor = 0.1, autovacuum_vacuum_threshold = 1000, autovacuum_analyze_scale_factor = 0.1, autovacuum_analyze_threshold = 1000);
ALTER TABLE History_0110 SET (parallel_workers = 4);

CREATE TABLE IF NOT EXISTS History_0111 PARTITION OF History FOR VALUES WITH (MODULUS 128, REMAINDER 111);
ALTER TABLE History_0111 SET (fillfactor = 100);
ALTER TABLE History_0111 SET (autovacuum_vacuum_scale_factor = 0.1, autovacuum_vacuum_threshold = 1000, autovacuum_analyze_scale_factor = 0.1, autovacuum_analyze_threshold = 1000);
ALTER TABLE History_0111 SET (parallel_workers = 4);

CREATE TABLE IF NOT EXISTS History_0112 PARTITION OF History FOR VALUES WITH (MODULUS 128, REMAINDER 112);
ALTER TABLE History_0112 SET (fillfactor = 100);
ALTER TABLE History_0112 SET (autovacuum_vacuum_scale_factor = 0.1, autovacuum_vacuum_threshold = 1000, autovacuum_analyze_scale_factor = 0.1, autovacuum_analyze_threshold = 1000);
ALTER TABLE History_0112 SET (parallel_workers = 4);

CREATE TABLE IF NOT EXISTS History_0113 PARTITION OF History FOR VALUES WITH (MODULUS 128, REMAINDER 113);
ALTER TABLE History_0113 SET (fillfactor = 100);
ALTER TABLE History_0113 SET (autovacuum_vacuum_scale_factor = 0.1, autovacuum_vacuum_threshold = 1000, autovacuum_analyze_scale_factor = 0.1, autovacuum_analyze_threshold = 1000);
ALTER TABLE History_0113 SET (parallel_workers = 4);

CREATE TABLE IF NOT EXISTS History_0114 PARTITION OF History FOR VALUES WITH (MODULUS 128, REMAINDER 114);
ALTER TABLE History_0114 SET (fillfactor = 100);
ALTER TABLE History_0114 SET (autovacuum_vacuum_scale_factor = 0.1, autovacuum_vacuum_threshold = 1000, autovacuum_analyze_scale_factor = 0.1, autovacuum_analyze_threshold = 1000);
ALTER TABLE History_0114 SET (parallel_workers = 4);

CREATE TABLE IF NOT EXISTS History_0115 PARTITION OF History FOR VALUES WITH (MODULUS 128, REMAINDER 115);
ALTER TABLE History_0115 SET (fillfactor = 100);
ALTER TABLE History_0115 SET (autovacuum_vacuum_scale_factor = 0.1, autovacuum_vacuum_threshold = 1000, autovacuum_analyze_scale_factor = 0.1, autovacuum_analyze_threshold = 1000);
ALTER TABLE History_0115 SET (parallel_workers = 4);

CREATE TABLE IF NOT EXISTS History_0116 PARTITION OF History FOR VALUES WITH (MODULUS 128, REMAINDER 116);
ALTER TABLE History_0116 SET (fillfactor = 100);
ALTER TABLE History_0116 SET (autovacuum_vacuum_scale_factor = 0.1, autovacuum_vacuum_threshold = 1000, autovacuum_analyze_scale_factor = 0.1, autovacuum_analyze_threshold = 1000);
ALTER TABLE History_0116 SET (parallel_workers = 4);

CREATE TABLE IF NOT EXISTS History_0117 PARTITION OF History FOR VALUES WITH (MODULUS 128, REMAINDER 117);
ALTER TABLE History_0117 SET (fillfactor = 100);
ALTER TABLE History_0117 SET (autovacuum_vacuum_scale_factor = 0.1, autovacuum_vacuum_threshold = 1000, autovacuum_analyze_scale_factor = 0.1, autovacuum_analyze_threshold = 1000);
ALTER TABLE History_0117 SET (parallel_workers = 4);

CREATE TABLE IF NOT EXISTS History_0118 PARTITION OF History FOR VALUES WITH (MODULUS 128, REMAINDER 118);
ALTER TABLE History_0118 SET (fillfactor = 100);
ALTER TABLE History_0118 SET (autovacuum_vacuum_scale_factor = 0.1, autovacuum_vacuum_threshold = 1000, autovacuum_analyze_scale_factor = 0.1, autovacuum_analyze_threshold = 1000);
ALTER TABLE History_0118 SET (parallel_workers = 4);

CREATE TABLE IF NOT EXISTS History_0119 PARTITION OF History FOR VALUES WITH (MODULUS 128, REMAINDER 119);
ALTER TABLE History_0119 SET (fillfactor = 100);
ALTER TABLE History_0119 SET (autovacuum_vacuum_scale_factor = 0.1, autovacuum_vacuum_threshold = 1000, autovacuum_analyze_scale_factor = 0.1, autovacuum_analyze_threshold = 1000);
ALTER TABLE History_0119 SET (parallel_workers = 4);

CREATE TABLE IF NOT EXISTS History_0120 PARTITION OF History FOR VALUES WITH (MODULUS 128, REMAINDER 120);
ALTER TABLE History_0120 SET (fillfactor = 100);
ALTER TABLE History_0120 SET (autovacuum_vacuum_scale_factor = 0.1, autovacuum_vacuum_threshold = 1000, autovacuum_analyze_scale_factor = 0.1, autovacuum_analyze_threshold = 1000);
ALTER TABLE History_0120 SET (parallel_workers = 4);

CREATE TABLE IF NOT EXISTS History_0121 PARTITION OF History FOR VALUES WITH (MODULUS 128, REMAINDER 121);
ALTER TABLE History_0121 SET (fillfactor = 100);
ALTER TABLE History_0121 SET (autovacuum_vacuum_scale_factor = 0.1, autovacuum_vacuum_threshold = 1000, autovacuum_analyze_scale_factor = 0.1, autovacuum_analyze_threshold = 1000);
ALTER TABLE History_0121 SET (parallel_workers = 4);

CREATE TABLE IF NOT EXISTS History_0122 PARTITION OF History FOR VALUES WITH (MODULUS 128, REMAINDER 122);
ALTER TABLE History_0122 SET (fillfactor = 100);
ALTER TABLE History_0122 SET (autovacuum_vacuum_scale_factor = 0.1, autovacuum_vacuum_threshold = 1000, autovacuum_analyze_scale_factor = 0.1, autovacuum_analyze_threshold = 1000);
ALTER TABLE History_0122 SET (parallel_workers = 4);

CREATE TABLE IF NOT EXISTS History_0123 PARTITION OF History FOR VALUES WITH (MODULUS 128, REMAINDER 123);
ALTER TABLE History_0123 SET (fillfactor = 100);
ALTER TABLE History_0123 SET (autovacuum_vacuum_scale_factor = 0.1, autovacuum_vacuum_threshold = 1000, autovacuum_analyze_scale_factor = 0.1, autovacuum_analyze_threshold = 1000);
ALTER TABLE History_0123 SET (parallel_workers = 4);

CREATE TABLE IF NOT EXISTS History_0124 PARTITION OF History FOR VALUES WITH (MODULUS 128, REMAINDER 124);
ALTER TABLE History_0124 SET (fillfactor = 100);
ALTER TABLE History_0124 SET (autovacuum_vacuum_scale_factor = 0.1, autovacuum_vacuum_threshold = 1000, autovacuum_analyze_scale_factor = 0.1, autovacuum_analyze_threshold = 1000);
ALTER TABLE History_0124 SET (parallel_workers = 4);

CREATE TABLE IF NOT EXISTS History_0125 PARTITION OF History FOR VALUES WITH (MODULUS 128, REMAINDER 125);
ALTER TABLE History_0125 SET (fillfactor = 100);
ALTER TABLE History_0125 SET (autovacuum_vacuum_scale_factor = 0.1, autovacuum_vacuum_threshold = 1000, autovacuum_analyze_scale_factor = 0.1, autovacuum_analyze_threshold = 1000);
ALTER TABLE History_0125 SET (parallel_workers = 4);

CREATE TABLE IF NOT EXISTS History_0126 PARTITION OF History FOR VALUES WITH (MODULUS 128, REMAINDER 126);
ALTER TABLE History_0126 SET (fillfactor = 100);
ALTER TABLE History_0126 SET (autovacuum_vacuum_scale_factor = 0.1, autovacuum_vacuum_threshold = 1000, autovacuum_analyze_scale_factor = 0.1, autovacuum_analyze_threshold = 1000);
ALTER TABLE History_0126 SET (parallel_workers = 4);

CREATE TABLE IF NOT EXISTS History_0127 PARTITION OF History FOR VALUES WITH (MODULUS 128, REMAINDER 127);
ALTER TABLE History_0127 SET (fillfactor = 100);
ALTER TABLE History_0127 SET (autovacuum_vacuum_scale_factor = 0.1, autovacuum_vacuum_threshold = 1000, autovacuum_analyze_scale_factor = 0.1, autovacuum_analyze_threshold = 1000);
ALTER TABLE History_0127 SET (parallel_workers = 4);

-- ============================================================================
-- NewEvents Table (with partitioning and performance optimizations)
-- ============================================================================
CREATE TABLE IF NOT EXISTS NewEvents (
    SequenceNumber BIGSERIAL,  -- Changed to BIGSERIAL for high scale
    InstanceID TEXT NOT NULL,
    ExecutionID TEXT NULL,
    Timestamp TIMESTAMP NOT NULL DEFAULT NOW(),
    VisibleTime TIMESTAMP NULL, -- for scheduled or abandoned messages
    EventPayload BYTEA NOT NULL,
    UNIQUE (InstanceID, SequenceNumber)
) PARTITION BY HASH (InstanceID);

-- Create 128 partitions for parallelism with storage parameters
CREATE TABLE IF NOT EXISTS NewEvents_0000 PARTITION OF NewEvents FOR VALUES WITH (MODULUS 128, REMAINDER 0);
ALTER TABLE NewEvents_0000 SET (fillfactor = 70);
ALTER TABLE NewEvents_0000 SET (autovacuum_vacuum_scale_factor = 0.05, autovacuum_vacuum_threshold = 5000, autovacuum_analyze_scale_factor = 0.05, autovacuum_analyze_threshold = 2000);

CREATE TABLE IF NOT EXISTS NewEvents_0001 PARTITION OF NewEvents FOR VALUES WITH (MODULUS 128, REMAINDER 1);
ALTER TABLE NewEvents_0001 SET (fillfactor = 70);
ALTER TABLE NewEvents_0001 SET (autovacuum_vacuum_scale_factor = 0.05, autovacuum_vacuum_threshold = 5000, autovacuum_analyze_scale_factor = 0.05, autovacuum_analyze_threshold = 2000);

CREATE TABLE IF NOT EXISTS NewEvents_0002 PARTITION OF NewEvents FOR VALUES WITH (MODULUS 128, REMAINDER 2);
ALTER TABLE NewEvents_0002 SET (fillfactor = 70);
ALTER TABLE NewEvents_0002 SET (autovacuum_vacuum_scale_factor = 0.05, autovacuum_vacuum_threshold = 5000, autovacuum_analyze_scale_factor = 0.05, autovacuum_analyze_threshold = 2000);

CREATE TABLE IF NOT EXISTS NewEvents_0003 PARTITION OF NewEvents FOR VALUES WITH (MODULUS 128, REMAINDER 3);
ALTER TABLE NewEvents_0003 SET (fillfactor = 70);
ALTER TABLE NewEvents_0003 SET (autovacuum_vacuum_scale_factor = 0.05, autovacuum_vacuum_threshold = 5000, autovacuum_analyze_scale_factor = 0.05, autovacuum_analyze_threshold = 2000);

CREATE TABLE IF NOT EXISTS NewEvents_0004 PARTITION OF NewEvents FOR VALUES WITH (MODULUS 128, REMAINDER 4);
ALTER TABLE NewEvents_0004 SET (fillfactor = 70);
ALTER TABLE NewEvents_0004 SET (autovacuum_vacuum_scale_factor = 0.05, autovacuum_vacuum_threshold = 5000, autovacuum_analyze_scale_factor = 0.05, autovacuum_analyze_threshold = 2000);

CREATE TABLE IF NOT EXISTS NewEvents_0005 PARTITION OF NewEvents FOR VALUES WITH (MODULUS 128, REMAINDER 5);
ALTER TABLE NewEvents_0005 SET (fillfactor = 70);
ALTER TABLE NewEvents_0005 SET (autovacuum_vacuum_scale_factor = 0.05, autovacuum_vacuum_threshold = 5000, autovacuum_analyze_scale_factor = 0.05, autovacuum_analyze_threshold = 2000);

CREATE TABLE IF NOT EXISTS NewEvents_0006 PARTITION OF NewEvents FOR VALUES WITH (MODULUS 128, REMAINDER 6);
ALTER TABLE NewEvents_0006 SET (fillfactor = 70);
ALTER TABLE NewEvents_0006 SET (autovacuum_vacuum_scale_factor = 0.05, autovacuum_vacuum_threshold = 5000, autovacuum_analyze_scale_factor = 0.05, autovacuum_analyze_threshold = 2000);

CREATE TABLE IF NOT EXISTS NewEvents_0007 PARTITION OF NewEvents FOR VALUES WITH (MODULUS 128, REMAINDER 7);
ALTER TABLE NewEvents_0007 SET (fillfactor = 70);
ALTER TABLE NewEvents_0007 SET (autovacuum_vacuum_scale_factor = 0.05, autovacuum_vacuum_threshold = 5000, autovacuum_analyze_scale_factor = 0.05, autovacuum_analyze_threshold = 2000);

CREATE TABLE IF NOT EXISTS NewEvents_0008 PARTITION OF NewEvents FOR VALUES WITH (MODULUS 128, REMAINDER 8);
ALTER TABLE NewEvents_0008 SET (fillfactor = 70);
ALTER TABLE NewEvents_0008 SET (autovacuum_vacuum_scale_factor = 0.05, autovacuum_vacuum_threshold = 5000, autovacuum_analyze_scale_factor = 0.05, autovacuum_analyze_threshold = 2000);

CREATE TABLE IF NOT EXISTS NewEvents_0009 PARTITION OF NewEvents FOR VALUES WITH (MODULUS 128, REMAINDER 9);
ALTER TABLE NewEvents_0009 SET (fillfactor = 70);
ALTER TABLE NewEvents_0009 SET (autovacuum_vacuum_scale_factor = 0.05, autovacuum_vacuum_threshold = 5000, autovacuum_analyze_scale_factor = 0.05, autovacuum_analyze_threshold = 2000);

CREATE TABLE IF NOT EXISTS NewEvents_0010 PARTITION OF NewEvents FOR VALUES WITH (MODULUS 128, REMAINDER 10);
ALTER TABLE NewEvents_0010 SET (fillfactor = 70);
ALTER TABLE NewEvents_0010 SET (autovacuum_vacuum_scale_factor = 0.05, autovacuum_vacuum_threshold = 5000, autovacuum_analyze_scale_factor = 0.05, autovacuum_analyze_threshold = 2000);

CREATE TABLE IF NOT EXISTS NewEvents_0011 PARTITION OF NewEvents FOR VALUES WITH (MODULUS 128, REMAINDER 11);
ALTER TABLE NewEvents_0011 SET (fillfactor = 70);
ALTER TABLE NewEvents_0011 SET (autovacuum_vacuum_scale_factor = 0.05, autovacuum_vacuum_threshold = 5000, autovacuum_analyze_scale_factor = 0.05, autovacuum_analyze_threshold = 2000);

CREATE TABLE IF NOT EXISTS NewEvents_0012 PARTITION OF NewEvents FOR VALUES WITH (MODULUS 128, REMAINDER 12);
ALTER TABLE NewEvents_0012 SET (fillfactor = 70);
ALTER TABLE NewEvents_0012 SET (autovacuum_vacuum_scale_factor = 0.05, autovacuum_vacuum_threshold = 5000, autovacuum_analyze_scale_factor = 0.05, autovacuum_analyze_threshold = 2000);

CREATE TABLE IF NOT EXISTS NewEvents_0013 PARTITION OF NewEvents FOR VALUES WITH (MODULUS 128, REMAINDER 13);
ALTER TABLE NewEvents_0013 SET (fillfactor = 70);
ALTER TABLE NewEvents_0013 SET (autovacuum_vacuum_scale_factor = 0.05, autovacuum_vacuum_threshold = 5000, autovacuum_analyze_scale_factor = 0.05, autovacuum_analyze_threshold = 2000);

CREATE TABLE IF NOT EXISTS NewEvents_0014 PARTITION OF NewEvents FOR VALUES WITH (MODULUS 128, REMAINDER 14);
ALTER TABLE NewEvents_0014 SET (fillfactor = 70);
ALTER TABLE NewEvents_0014 SET (autovacuum_vacuum_scale_factor = 0.05, autovacuum_vacuum_threshold = 5000, autovacuum_analyze_scale_factor = 0.05, autovacuum_analyze_threshold = 2000);

CREATE TABLE IF NOT EXISTS NewEvents_0015 PARTITION OF NewEvents FOR VALUES WITH (MODULUS 128, REMAINDER 15);
ALTER TABLE NewEvents_0015 SET (fillfactor = 70);
ALTER TABLE NewEvents_0015 SET (autovacuum_vacuum_scale_factor = 0.05, autovacuum_vacuum_threshold = 5000, autovacuum_analyze_scale_factor = 0.05, autovacuum_analyze_threshold = 2000);

CREATE TABLE IF NOT EXISTS NewEvents_0016 PARTITION OF NewEvents FOR VALUES WITH (MODULUS 128, REMAINDER 16);
ALTER TABLE NewEvents_0016 SET (fillfactor = 70);
ALTER TABLE NewEvents_0016 SET (autovacuum_vacuum_scale_factor = 0.05, autovacuum_vacuum_threshold = 5000, autovacuum_analyze_scale_factor = 0.05, autovacuum_analyze_threshold = 2000);

CREATE TABLE IF NOT EXISTS NewEvents_0017 PARTITION OF NewEvents FOR VALUES WITH (MODULUS 128, REMAINDER 17);
ALTER TABLE NewEvents_0017 SET (fillfactor = 70);
ALTER TABLE NewEvents_0017 SET (autovacuum_vacuum_scale_factor = 0.05, autovacuum_vacuum_threshold = 5000, autovacuum_analyze_scale_factor = 0.05, autovacuum_analyze_threshold = 2000);

CREATE TABLE IF NOT EXISTS NewEvents_0018 PARTITION OF NewEvents FOR VALUES WITH (MODULUS 128, REMAINDER 18);
ALTER TABLE NewEvents_0018 SET (fillfactor = 70);
ALTER TABLE NewEvents_0018 SET (autovacuum_vacuum_scale_factor = 0.05, autovacuum_vacuum_threshold = 5000, autovacuum_analyze_scale_factor = 0.05, autovacuum_analyze_threshold = 2000);

CREATE TABLE IF NOT EXISTS NewEvents_0019 PARTITION OF NewEvents FOR VALUES WITH (MODULUS 128, REMAINDER 19);
ALTER TABLE NewEvents_0019 SET (fillfactor = 70);
ALTER TABLE NewEvents_0019 SET (autovacuum_vacuum_scale_factor = 0.05, autovacuum_vacuum_threshold = 5000, autovacuum_analyze_scale_factor = 0.05, autovacuum_analyze_threshold = 2000);

CREATE TABLE IF NOT EXISTS NewEvents_0020 PARTITION OF NewEvents FOR VALUES WITH (MODULUS 128, REMAINDER 20);
ALTER TABLE NewEvents_0020 SET (fillfactor = 70);
ALTER TABLE NewEvents_0020 SET (autovacuum_vacuum_scale_factor = 0.05, autovacuum_vacuum_threshold = 5000, autovacuum_analyze_scale_factor = 0.05, autovacuum_analyze_threshold = 2000);

CREATE TABLE IF NOT EXISTS NewEvents_0021 PARTITION OF NewEvents FOR VALUES WITH (MODULUS 128, REMAINDER 21);
ALTER TABLE NewEvents_0021 SET (fillfactor = 70);
ALTER TABLE NewEvents_0021 SET (autovacuum_vacuum_scale_factor = 0.05, autovacuum_vacuum_threshold = 5000, autovacuum_analyze_scale_factor = 0.05, autovacuum_analyze_threshold = 2000);

CREATE TABLE IF NOT EXISTS NewEvents_0022 PARTITION OF NewEvents FOR VALUES WITH (MODULUS 128, REMAINDER 22);
ALTER TABLE NewEvents_0022 SET (fillfactor = 70);
ALTER TABLE NewEvents_0022 SET (autovacuum_vacuum_scale_factor = 0.05, autovacuum_vacuum_threshold = 5000, autovacuum_analyze_scale_factor = 0.05, autovacuum_analyze_threshold = 2000);

CREATE TABLE IF NOT EXISTS NewEvents_0023 PARTITION OF NewEvents FOR VALUES WITH (MODULUS 128, REMAINDER 23);
ALTER TABLE NewEvents_0023 SET (fillfactor = 70);
ALTER TABLE NewEvents_0023 SET (autovacuum_vacuum_scale_factor = 0.05, autovacuum_vacuum_threshold = 5000, autovacuum_analyze_scale_factor = 0.05, autovacuum_analyze_threshold = 2000);

CREATE TABLE IF NOT EXISTS NewEvents_0024 PARTITION OF NewEvents FOR VALUES WITH (MODULUS 128, REMAINDER 24);
ALTER TABLE NewEvents_0024 SET (fillfactor = 70);
ALTER TABLE NewEvents_0024 SET (autovacuum_vacuum_scale_factor = 0.05, autovacuum_vacuum_threshold = 5000, autovacuum_analyze_scale_factor = 0.05, autovacuum_analyze_threshold = 2000);

CREATE TABLE IF NOT EXISTS NewEvents_0025 PARTITION OF NewEvents FOR VALUES WITH (MODULUS 128, REMAINDER 25);
ALTER TABLE NewEvents_0025 SET (fillfactor = 70);
ALTER TABLE NewEvents_0025 SET (autovacuum_vacuum_scale_factor = 0.05, autovacuum_vacuum_threshold = 5000, autovacuum_analyze_scale_factor = 0.05, autovacuum_analyze_threshold = 2000);

CREATE TABLE IF NOT EXISTS NewEvents_0026 PARTITION OF NewEvents FOR VALUES WITH (MODULUS 128, REMAINDER 26);
ALTER TABLE NewEvents_0026 SET (fillfactor = 70);
ALTER TABLE NewEvents_0026 SET (autovacuum_vacuum_scale_factor = 0.05, autovacuum_vacuum_threshold = 5000, autovacuum_analyze_scale_factor = 0.05, autovacuum_analyze_threshold = 2000);

CREATE TABLE IF NOT EXISTS NewEvents_0027 PARTITION OF NewEvents FOR VALUES WITH (MODULUS 128, REMAINDER 27);
ALTER TABLE NewEvents_0027 SET (fillfactor = 70);
ALTER TABLE NewEvents_0027 SET (autovacuum_vacuum_scale_factor = 0.05, autovacuum_vacuum_threshold = 5000, autovacuum_analyze_scale_factor = 0.05, autovacuum_analyze_threshold = 2000);

CREATE TABLE IF NOT EXISTS NewEvents_0028 PARTITION OF NewEvents FOR VALUES WITH (MODULUS 128, REMAINDER 28);
ALTER TABLE NewEvents_0028 SET (fillfactor = 70);
ALTER TABLE NewEvents_0028 SET (autovacuum_vacuum_scale_factor = 0.05, autovacuum_vacuum_threshold = 5000, autovacuum_analyze_scale_factor = 0.05, autovacuum_analyze_threshold = 2000);

CREATE TABLE IF NOT EXISTS NewEvents_0029 PARTITION OF NewEvents FOR VALUES WITH (MODULUS 128, REMAINDER 29);
ALTER TABLE NewEvents_0029 SET (fillfactor = 70);
ALTER TABLE NewEvents_0029 SET (autovacuum_vacuum_scale_factor = 0.05, autovacuum_vacuum_threshold = 5000, autovacuum_analyze_scale_factor = 0.05, autovacuum_analyze_threshold = 2000);

CREATE TABLE IF NOT EXISTS NewEvents_0030 PARTITION OF NewEvents FOR VALUES WITH (MODULUS 128, REMAINDER 30);
ALTER TABLE NewEvents_0030 SET (fillfactor = 70);
ALTER TABLE NewEvents_0030 SET (autovacuum_vacuum_scale_factor = 0.05, autovacuum_vacuum_threshold = 5000, autovacuum_analyze_scale_factor = 0.05, autovacuum_analyze_threshold = 2000);

CREATE TABLE IF NOT EXISTS NewEvents_0031 PARTITION OF NewEvents FOR VALUES WITH (MODULUS 128, REMAINDER 31);
ALTER TABLE NewEvents_0031 SET (fillfactor = 70);
ALTER TABLE NewEvents_0031 SET (autovacuum_vacuum_scale_factor = 0.05, autovacuum_vacuum_threshold = 5000, autovacuum_analyze_scale_factor = 0.05, autovacuum_analyze_threshold = 2000);

CREATE TABLE IF NOT EXISTS NewEvents_0032 PARTITION OF NewEvents FOR VALUES WITH (MODULUS 128, REMAINDER 32);
ALTER TABLE NewEvents_0032 SET (fillfactor = 70);
ALTER TABLE NewEvents_0032 SET (autovacuum_vacuum_scale_factor = 0.05, autovacuum_vacuum_threshold = 5000, autovacuum_analyze_scale_factor = 0.05, autovacuum_analyze_threshold = 2000);

CREATE TABLE IF NOT EXISTS NewEvents_0033 PARTITION OF NewEvents FOR VALUES WITH (MODULUS 128, REMAINDER 33);
ALTER TABLE NewEvents_0033 SET (fillfactor = 70);
ALTER TABLE NewEvents_0033 SET (autovacuum_vacuum_scale_factor = 0.05, autovacuum_vacuum_threshold = 5000, autovacuum_analyze_scale_factor = 0.05, autovacuum_analyze_threshold = 2000);

CREATE TABLE IF NOT EXISTS NewEvents_0034 PARTITION OF NewEvents FOR VALUES WITH (MODULUS 128, REMAINDER 34);
ALTER TABLE NewEvents_0034 SET (fillfactor = 70);
ALTER TABLE NewEvents_0034 SET (autovacuum_vacuum_scale_factor = 0.05, autovacuum_vacuum_threshold = 5000, autovacuum_analyze_scale_factor = 0.05, autovacuum_analyze_threshold = 2000);

CREATE TABLE IF NOT EXISTS NewEvents_0035 PARTITION OF NewEvents FOR VALUES WITH (MODULUS 128, REMAINDER 35);
ALTER TABLE NewEvents_0035 SET (fillfactor = 70);
ALTER TABLE NewEvents_0035 SET (autovacuum_vacuum_scale_factor = 0.05, autovacuum_vacuum_threshold = 5000, autovacuum_analyze_scale_factor = 0.05, autovacuum_analyze_threshold = 2000);

CREATE TABLE IF NOT EXISTS NewEvents_0036 PARTITION OF NewEvents FOR VALUES WITH (MODULUS 128, REMAINDER 36);
ALTER TABLE NewEvents_0036 SET (fillfactor = 70);
ALTER TABLE NewEvents_0036 SET (autovacuum_vacuum_scale_factor = 0.05, autovacuum_vacuum_threshold = 5000, autovacuum_analyze_scale_factor = 0.05, autovacuum_analyze_threshold = 2000);

CREATE TABLE IF NOT EXISTS NewEvents_0037 PARTITION OF NewEvents FOR VALUES WITH (MODULUS 128, REMAINDER 37);
ALTER TABLE NewEvents_0037 SET (fillfactor = 70);
ALTER TABLE NewEvents_0037 SET (autovacuum_vacuum_scale_factor = 0.05, autovacuum_vacuum_threshold = 5000, autovacuum_analyze_scale_factor = 0.05, autovacuum_analyze_threshold = 2000);

CREATE TABLE IF NOT EXISTS NewEvents_0038 PARTITION OF NewEvents FOR VALUES WITH (MODULUS 128, REMAINDER 38);
ALTER TABLE NewEvents_0038 SET (fillfactor = 70);
ALTER TABLE NewEvents_0038 SET (autovacuum_vacuum_scale_factor = 0.05, autovacuum_vacuum_threshold = 5000, autovacuum_analyze_scale_factor = 0.05, autovacuum_analyze_threshold = 2000);

CREATE TABLE IF NOT EXISTS NewEvents_0039 PARTITION OF NewEvents FOR VALUES WITH (MODULUS 128, REMAINDER 39);
ALTER TABLE NewEvents_0039 SET (fillfactor = 70);
ALTER TABLE NewEvents_0039 SET (autovacuum_vacuum_scale_factor = 0.05, autovacuum_vacuum_threshold = 5000, autovacuum_analyze_scale_factor = 0.05, autovacuum_analyze_threshold = 2000);

CREATE TABLE IF NOT EXISTS NewEvents_0040 PARTITION OF NewEvents FOR VALUES WITH (MODULUS 128, REMAINDER 40);
ALTER TABLE NewEvents_0040 SET (fillfactor = 70);
ALTER TABLE NewEvents_0040 SET (autovacuum_vacuum_scale_factor = 0.05, autovacuum_vacuum_threshold = 5000, autovacuum_analyze_scale_factor = 0.05, autovacuum_analyze_threshold = 2000);

CREATE TABLE IF NOT EXISTS NewEvents_0041 PARTITION OF NewEvents FOR VALUES WITH (MODULUS 128, REMAINDER 41);
ALTER TABLE NewEvents_0041 SET (fillfactor = 70);
ALTER TABLE NewEvents_0041 SET (autovacuum_vacuum_scale_factor = 0.05, autovacuum_vacuum_threshold = 5000, autovacuum_analyze_scale_factor = 0.05, autovacuum_analyze_threshold = 2000);

CREATE TABLE IF NOT EXISTS NewEvents_0042 PARTITION OF NewEvents FOR VALUES WITH (MODULUS 128, REMAINDER 42);
ALTER TABLE NewEvents_0042 SET (fillfactor = 70);
ALTER TABLE NewEvents_0042 SET (autovacuum_vacuum_scale_factor = 0.05, autovacuum_vacuum_threshold = 5000, autovacuum_analyze_scale_factor = 0.05, autovacuum_analyze_threshold = 2000);

CREATE TABLE IF NOT EXISTS NewEvents_0043 PARTITION OF NewEvents FOR VALUES WITH (MODULUS 128, REMAINDER 43);
ALTER TABLE NewEvents_0043 SET (fillfactor = 70);
ALTER TABLE NewEvents_0043 SET (autovacuum_vacuum_scale_factor = 0.05, autovacuum_vacuum_threshold = 5000, autovacuum_analyze_scale_factor = 0.05, autovacuum_analyze_threshold = 2000);

CREATE TABLE IF NOT EXISTS NewEvents_0044 PARTITION OF NewEvents FOR VALUES WITH (MODULUS 128, REMAINDER 44);
ALTER TABLE NewEvents_0044 SET (fillfactor = 70);
ALTER TABLE NewEvents_0044 SET (autovacuum_vacuum_scale_factor = 0.05, autovacuum_vacuum_threshold = 5000, autovacuum_analyze_scale_factor = 0.05, autovacuum_analyze_threshold = 2000);

CREATE TABLE IF NOT EXISTS NewEvents_0045 PARTITION OF NewEvents FOR VALUES WITH (MODULUS 128, REMAINDER 45);
ALTER TABLE NewEvents_0045 SET (fillfactor = 70);
ALTER TABLE NewEvents_0045 SET (autovacuum_vacuum_scale_factor = 0.05, autovacuum_vacuum_threshold = 5000, autovacuum_analyze_scale_factor = 0.05, autovacuum_analyze_threshold = 2000);

CREATE TABLE IF NOT EXISTS NewEvents_0046 PARTITION OF NewEvents FOR VALUES WITH (MODULUS 128, REMAINDER 46);
ALTER TABLE NewEvents_0046 SET (fillfactor = 70);
ALTER TABLE NewEvents_0046 SET (autovacuum_vacuum_scale_factor = 0.05, autovacuum_vacuum_threshold = 5000, autovacuum_analyze_scale_factor = 0.05, autovacuum_analyze_threshold = 2000);

CREATE TABLE IF NOT EXISTS NewEvents_0047 PARTITION OF NewEvents FOR VALUES WITH (MODULUS 128, REMAINDER 47);
ALTER TABLE NewEvents_0047 SET (fillfactor = 70);
ALTER TABLE NewEvents_0047 SET (autovacuum_vacuum_scale_factor = 0.05, autovacuum_vacuum_threshold = 5000, autovacuum_analyze_scale_factor = 0.05, autovacuum_analyze_threshold = 2000);

CREATE TABLE IF NOT EXISTS NewEvents_0048 PARTITION OF NewEvents FOR VALUES WITH (MODULUS 128, REMAINDER 48);
ALTER TABLE NewEvents_0048 SET (fillfactor = 70);
ALTER TABLE NewEvents_0048 SET (autovacuum_vacuum_scale_factor = 0.05, autovacuum_vacuum_threshold = 5000, autovacuum_analyze_scale_factor = 0.05, autovacuum_analyze_threshold = 2000);

CREATE TABLE IF NOT EXISTS NewEvents_0049 PARTITION OF NewEvents FOR VALUES WITH (MODULUS 128, REMAINDER 49);
ALTER TABLE NewEvents_0049 SET (fillfactor = 70);
ALTER TABLE NewEvents_0049 SET (autovacuum_vacuum_scale_factor = 0.05, autovacuum_vacuum_threshold = 5000, autovacuum_analyze_scale_factor = 0.05, autovacuum_analyze_threshold = 2000);

CREATE TABLE IF NOT EXISTS NewEvents_0050 PARTITION OF NewEvents FOR VALUES WITH (MODULUS 128, REMAINDER 50);
ALTER TABLE NewEvents_0050 SET (fillfactor = 70);
ALTER TABLE NewEvents_0050 SET (autovacuum_vacuum_scale_factor = 0.05, autovacuum_vacuum_threshold = 5000, autovacuum_analyze_scale_factor = 0.05, autovacuum_analyze_threshold = 2000);

CREATE TABLE IF NOT EXISTS NewEvents_0051 PARTITION OF NewEvents FOR VALUES WITH (MODULUS 128, REMAINDER 51);
ALTER TABLE NewEvents_0051 SET (fillfactor = 70);
ALTER TABLE NewEvents_0051 SET (autovacuum_vacuum_scale_factor = 0.05, autovacuum_vacuum_threshold = 5000, autovacuum_analyze_scale_factor = 0.05, autovacuum_analyze_threshold = 2000);

CREATE TABLE IF NOT EXISTS NewEvents_0052 PARTITION OF NewEvents FOR VALUES WITH (MODULUS 128, REMAINDER 52);
ALTER TABLE NewEvents_0052 SET (fillfactor = 70);
ALTER TABLE NewEvents_0052 SET (autovacuum_vacuum_scale_factor = 0.05, autovacuum_vacuum_threshold = 5000, autovacuum_analyze_scale_factor = 0.05, autovacuum_analyze_threshold = 2000);

CREATE TABLE IF NOT EXISTS NewEvents_0053 PARTITION OF NewEvents FOR VALUES WITH (MODULUS 128, REMAINDER 53);
ALTER TABLE NewEvents_0053 SET (fillfactor = 70);
ALTER TABLE NewEvents_0053 SET (autovacuum_vacuum_scale_factor = 0.05, autovacuum_vacuum_threshold = 5000, autovacuum_analyze_scale_factor = 0.05, autovacuum_analyze_threshold = 2000);

CREATE TABLE IF NOT EXISTS NewEvents_0054 PARTITION OF NewEvents FOR VALUES WITH (MODULUS 128, REMAINDER 54);
ALTER TABLE NewEvents_0054 SET (fillfactor = 70);
ALTER TABLE NewEvents_0054 SET (autovacuum_vacuum_scale_factor = 0.05, autovacuum_vacuum_threshold = 5000, autovacuum_analyze_scale_factor = 0.05, autovacuum_analyze_threshold = 2000);

CREATE TABLE IF NOT EXISTS NewEvents_0055 PARTITION OF NewEvents FOR VALUES WITH (MODULUS 128, REMAINDER 55);
ALTER TABLE NewEvents_0055 SET (fillfactor = 70);
ALTER TABLE NewEvents_0055 SET (autovacuum_vacuum_scale_factor = 0.05, autovacuum_vacuum_threshold = 5000, autovacuum_analyze_scale_factor = 0.05, autovacuum_analyze_threshold = 2000);

CREATE TABLE IF NOT EXISTS NewEvents_0056 PARTITION OF NewEvents FOR VALUES WITH (MODULUS 128, REMAINDER 56);
ALTER TABLE NewEvents_0056 SET (fillfactor = 70);
ALTER TABLE NewEvents_0056 SET (autovacuum_vacuum_scale_factor = 0.05, autovacuum_vacuum_threshold = 5000, autovacuum_analyze_scale_factor = 0.05, autovacuum_analyze_threshold = 2000);

CREATE TABLE IF NOT EXISTS NewEvents_0057 PARTITION OF NewEvents FOR VALUES WITH (MODULUS 128, REMAINDER 57);
ALTER TABLE NewEvents_0057 SET (fillfactor = 70);
ALTER TABLE NewEvents_0057 SET (autovacuum_vacuum_scale_factor = 0.05, autovacuum_vacuum_threshold = 5000, autovacuum_analyze_scale_factor = 0.05, autovacuum_analyze_threshold = 2000);

CREATE TABLE IF NOT EXISTS NewEvents_0058 PARTITION OF NewEvents FOR VALUES WITH (MODULUS 128, REMAINDER 58);
ALTER TABLE NewEvents_0058 SET (fillfactor = 70);
ALTER TABLE NewEvents_0058 SET (autovacuum_vacuum_scale_factor = 0.05, autovacuum_vacuum_threshold = 5000, autovacuum_analyze_scale_factor = 0.05, autovacuum_analyze_threshold = 2000);

CREATE TABLE IF NOT EXISTS NewEvents_0059 PARTITION OF NewEvents FOR VALUES WITH (MODULUS 128, REMAINDER 59);
ALTER TABLE NewEvents_0059 SET (fillfactor = 70);
ALTER TABLE NewEvents_0059 SET (autovacuum_vacuum_scale_factor = 0.05, autovacuum_vacuum_threshold = 5000, autovacuum_analyze_scale_factor = 0.05, autovacuum_analyze_threshold = 2000);

CREATE TABLE IF NOT EXISTS NewEvents_0060 PARTITION OF NewEvents FOR VALUES WITH (MODULUS 128, REMAINDER 60);
ALTER TABLE NewEvents_0060 SET (fillfactor = 70);
ALTER TABLE NewEvents_0060 SET (autovacuum_vacuum_scale_factor = 0.05, autovacuum_vacuum_threshold = 5000, autovacuum_analyze_scale_factor = 0.05, autovacuum_analyze_threshold = 2000);

CREATE TABLE IF NOT EXISTS NewEvents_0061 PARTITION OF NewEvents FOR VALUES WITH (MODULUS 128, REMAINDER 61);
ALTER TABLE NewEvents_0061 SET (fillfactor = 70);
ALTER TABLE NewEvents_0061 SET (autovacuum_vacuum_scale_factor = 0.05, autovacuum_vacuum_threshold = 5000, autovacuum_analyze_scale_factor = 0.05, autovacuum_analyze_threshold = 2000);

CREATE TABLE IF NOT EXISTS NewEvents_0062 PARTITION OF NewEvents FOR VALUES WITH (MODULUS 128, REMAINDER 62);
ALTER TABLE NewEvents_0062 SET (fillfactor = 70);
ALTER TABLE NewEvents_0062 SET (autovacuum_vacuum_scale_factor = 0.05, autovacuum_vacuum_threshold = 5000, autovacuum_analyze_scale_factor = 0.05, autovacuum_analyze_threshold = 2000);

CREATE TABLE IF NOT EXISTS NewEvents_0063 PARTITION OF NewEvents FOR VALUES WITH (MODULUS 128, REMAINDER 63);
ALTER TABLE NewEvents_0063 SET (fillfactor = 70);
ALTER TABLE NewEvents_0063 SET (autovacuum_vacuum_scale_factor = 0.05, autovacuum_vacuum_threshold = 5000, autovacuum_analyze_scale_factor = 0.05, autovacuum_analyze_threshold = 2000);

CREATE TABLE IF NOT EXISTS NewEvents_0064 PARTITION OF NewEvents FOR VALUES WITH (MODULUS 128, REMAINDER 64);
ALTER TABLE NewEvents_0064 SET (fillfactor = 70);
ALTER TABLE NewEvents_0064 SET (autovacuum_vacuum_scale_factor = 0.05, autovacuum_vacuum_threshold = 5000, autovacuum_analyze_scale_factor = 0.05, autovacuum_analyze_threshold = 2000);

CREATE TABLE IF NOT EXISTS NewEvents_0065 PARTITION OF NewEvents FOR VALUES WITH (MODULUS 128, REMAINDER 65);
ALTER TABLE NewEvents_0065 SET (fillfactor = 70);
ALTER TABLE NewEvents_0065 SET (autovacuum_vacuum_scale_factor = 0.05, autovacuum_vacuum_threshold = 5000, autovacuum_analyze_scale_factor = 0.05, autovacuum_analyze_threshold = 2000);

CREATE TABLE IF NOT EXISTS NewEvents_0066 PARTITION OF NewEvents FOR VALUES WITH (MODULUS 128, REMAINDER 66);
ALTER TABLE NewEvents_0066 SET (fillfactor = 70);
ALTER TABLE NewEvents_0066 SET (autovacuum_vacuum_scale_factor = 0.05, autovacuum_vacuum_threshold = 5000, autovacuum_analyze_scale_factor = 0.05, autovacuum_analyze_threshold = 2000);

CREATE TABLE IF NOT EXISTS NewEvents_0067 PARTITION OF NewEvents FOR VALUES WITH (MODULUS 128, REMAINDER 67);
ALTER TABLE NewEvents_0067 SET (fillfactor = 70);
ALTER TABLE NewEvents_0067 SET (autovacuum_vacuum_scale_factor = 0.05, autovacuum_vacuum_threshold = 5000, autovacuum_analyze_scale_factor = 0.05, autovacuum_analyze_threshold = 2000);

CREATE TABLE IF NOT EXISTS NewEvents_0068 PARTITION OF NewEvents FOR VALUES WITH (MODULUS 128, REMAINDER 68);
ALTER TABLE NewEvents_0068 SET (fillfactor = 70);
ALTER TABLE NewEvents_0068 SET (autovacuum_vacuum_scale_factor = 0.05, autovacuum_vacuum_threshold = 5000, autovacuum_analyze_scale_factor = 0.05, autovacuum_analyze_threshold = 2000);

CREATE TABLE IF NOT EXISTS NewEvents_0069 PARTITION OF NewEvents FOR VALUES WITH (MODULUS 128, REMAINDER 69);
ALTER TABLE NewEvents_0069 SET (fillfactor = 70);
ALTER TABLE NewEvents_0069 SET (autovacuum_vacuum_scale_factor = 0.05, autovacuum_vacuum_threshold = 5000, autovacuum_analyze_scale_factor = 0.05, autovacuum_analyze_threshold = 2000);

CREATE TABLE IF NOT EXISTS NewEvents_0070 PARTITION OF NewEvents FOR VALUES WITH (MODULUS 128, REMAINDER 70);
ALTER TABLE NewEvents_0070 SET (fillfactor = 70);
ALTER TABLE NewEvents_0070 SET (autovacuum_vacuum_scale_factor = 0.05, autovacuum_vacuum_threshold = 5000, autovacuum_analyze_scale_factor = 0.05, autovacuum_analyze_threshold = 2000);

CREATE TABLE IF NOT EXISTS NewEvents_0071 PARTITION OF NewEvents FOR VALUES WITH (MODULUS 128, REMAINDER 71);
ALTER TABLE NewEvents_0071 SET (fillfactor = 70);
ALTER TABLE NewEvents_0071 SET (autovacuum_vacuum_scale_factor = 0.05, autovacuum_vacuum_threshold = 5000, autovacuum_analyze_scale_factor = 0.05, autovacuum_analyze_threshold = 2000);

CREATE TABLE IF NOT EXISTS NewEvents_0072 PARTITION OF NewEvents FOR VALUES WITH (MODULUS 128, REMAINDER 72);
ALTER TABLE NewEvents_0072 SET (fillfactor = 70);
ALTER TABLE NewEvents_0072 SET (autovacuum_vacuum_scale_factor = 0.05, autovacuum_vacuum_threshold = 5000, autovacuum_analyze_scale_factor = 0.05, autovacuum_analyze_threshold = 2000);

CREATE TABLE IF NOT EXISTS NewEvents_0073 PARTITION OF NewEvents FOR VALUES WITH (MODULUS 128, REMAINDER 73);
ALTER TABLE NewEvents_0073 SET (fillfactor = 70);
ALTER TABLE NewEvents_0073 SET (autovacuum_vacuum_scale_factor = 0.05, autovacuum_vacuum_threshold = 5000, autovacuum_analyze_scale_factor = 0.05, autovacuum_analyze_threshold = 2000);

CREATE TABLE IF NOT EXISTS NewEvents_0074 PARTITION OF NewEvents FOR VALUES WITH (MODULUS 128, REMAINDER 74);
ALTER TABLE NewEvents_0074 SET (fillfactor = 70);
ALTER TABLE NewEvents_0074 SET (autovacuum_vacuum_scale_factor = 0.05, autovacuum_vacuum_threshold = 5000, autovacuum_analyze_scale_factor = 0.05, autovacuum_analyze_threshold = 2000);

CREATE TABLE IF NOT EXISTS NewEvents_0075 PARTITION OF NewEvents FOR VALUES WITH (MODULUS 128, REMAINDER 75);
ALTER TABLE NewEvents_0075 SET (fillfactor = 70);
ALTER TABLE NewEvents_0075 SET (autovacuum_vacuum_scale_factor = 0.05, autovacuum_vacuum_threshold = 5000, autovacuum_analyze_scale_factor = 0.05, autovacuum_analyze_threshold = 2000);

CREATE TABLE IF NOT EXISTS NewEvents_0076 PARTITION OF NewEvents FOR VALUES WITH (MODULUS 128, REMAINDER 76);
ALTER TABLE NewEvents_0076 SET (fillfactor = 70);
ALTER TABLE NewEvents_0076 SET (autovacuum_vacuum_scale_factor = 0.05, autovacuum_vacuum_threshold = 5000, autovacuum_analyze_scale_factor = 0.05, autovacuum_analyze_threshold = 2000);

CREATE TABLE IF NOT EXISTS NewEvents_0077 PARTITION OF NewEvents FOR VALUES WITH (MODULUS 128, REMAINDER 77);
ALTER TABLE NewEvents_0077 SET (fillfactor = 70);
ALTER TABLE NewEvents_0077 SET (autovacuum_vacuum_scale_factor = 0.05, autovacuum_vacuum_threshold = 5000, autovacuum_analyze_scale_factor = 0.05, autovacuum_analyze_threshold = 2000);

CREATE TABLE IF NOT EXISTS NewEvents_0078 PARTITION OF NewEvents FOR VALUES WITH (MODULUS 128, REMAINDER 78);
ALTER TABLE NewEvents_0078 SET (fillfactor = 70);
ALTER TABLE NewEvents_0078 SET (autovacuum_vacuum_scale_factor = 0.05, autovacuum_vacuum_threshold = 5000, autovacuum_analyze_scale_factor = 0.05, autovacuum_analyze_threshold = 2000);

CREATE TABLE IF NOT EXISTS NewEvents_0079 PARTITION OF NewEvents FOR VALUES WITH (MODULUS 128, REMAINDER 79);
ALTER TABLE NewEvents_0079 SET (fillfactor = 70);
ALTER TABLE NewEvents_0079 SET (autovacuum_vacuum_scale_factor = 0.05, autovacuum_vacuum_threshold = 5000, autovacuum_analyze_scale_factor = 0.05, autovacuum_analyze_threshold = 2000);

CREATE TABLE IF NOT EXISTS NewEvents_0080 PARTITION OF NewEvents FOR VALUES WITH (MODULUS 128, REMAINDER 80);
ALTER TABLE NewEvents_0080 SET (fillfactor = 70);
ALTER TABLE NewEvents_0080 SET (autovacuum_vacuum_scale_factor = 0.05, autovacuum_vacuum_threshold = 5000, autovacuum_analyze_scale_factor = 0.05, autovacuum_analyze_threshold = 2000);

CREATE TABLE IF NOT EXISTS NewEvents_0081 PARTITION OF NewEvents FOR VALUES WITH (MODULUS 128, REMAINDER 81);
ALTER TABLE NewEvents_0081 SET (fillfactor = 70);
ALTER TABLE NewEvents_0081 SET (autovacuum_vacuum_scale_factor = 0.05, autovacuum_vacuum_threshold = 5000, autovacuum_analyze_scale_factor = 0.05, autovacuum_analyze_threshold = 2000);

CREATE TABLE IF NOT EXISTS NewEvents_0082 PARTITION OF NewEvents FOR VALUES WITH (MODULUS 128, REMAINDER 82);
ALTER TABLE NewEvents_0082 SET (fillfactor = 70);
ALTER TABLE NewEvents_0082 SET (autovacuum_vacuum_scale_factor = 0.05, autovacuum_vacuum_threshold = 5000, autovacuum_analyze_scale_factor = 0.05, autovacuum_analyze_threshold = 2000);

CREATE TABLE IF NOT EXISTS NewEvents_0083 PARTITION OF NewEvents FOR VALUES WITH (MODULUS 128, REMAINDER 83);
ALTER TABLE NewEvents_0083 SET (fillfactor = 70);
ALTER TABLE NewEvents_0083 SET (autovacuum_vacuum_scale_factor = 0.05, autovacuum_vacuum_threshold = 5000, autovacuum_analyze_scale_factor = 0.05, autovacuum_analyze_threshold = 2000);

CREATE TABLE IF NOT EXISTS NewEvents_0084 PARTITION OF NewEvents FOR VALUES WITH (MODULUS 128, REMAINDER 84);
ALTER TABLE NewEvents_0084 SET (fillfactor = 70);
ALTER TABLE NewEvents_0084 SET (autovacuum_vacuum_scale_factor = 0.05, autovacuum_vacuum_threshold = 5000, autovacuum_analyze_scale_factor = 0.05, autovacuum_analyze_threshold = 2000);

CREATE TABLE IF NOT EXISTS NewEvents_0085 PARTITION OF NewEvents FOR VALUES WITH (MODULUS 128, REMAINDER 85);
ALTER TABLE NewEvents_0085 SET (fillfactor = 70);
ALTER TABLE NewEvents_0085 SET (autovacuum_vacuum_scale_factor = 0.05, autovacuum_vacuum_threshold = 5000, autovacuum_analyze_scale_factor = 0.05, autovacuum_analyze_threshold = 2000);

CREATE TABLE IF NOT EXISTS NewEvents_0086 PARTITION OF NewEvents FOR VALUES WITH (MODULUS 128, REMAINDER 86);
ALTER TABLE NewEvents_0086 SET (fillfactor = 70);
ALTER TABLE NewEvents_0086 SET (autovacuum_vacuum_scale_factor = 0.05, autovacuum_vacuum_threshold = 5000, autovacuum_analyze_scale_factor = 0.05, autovacuum_analyze_threshold = 2000);

CREATE TABLE IF NOT EXISTS NewEvents_0087 PARTITION OF NewEvents FOR VALUES WITH (MODULUS 128, REMAINDER 87);
ALTER TABLE NewEvents_0087 SET (fillfactor = 70);
ALTER TABLE NewEvents_0087 SET (autovacuum_vacuum_scale_factor = 0.05, autovacuum_vacuum_threshold = 5000, autovacuum_analyze_scale_factor = 0.05, autovacuum_analyze_threshold = 2000);

CREATE TABLE IF NOT EXISTS NewEvents_0088 PARTITION OF NewEvents FOR VALUES WITH (MODULUS 128, REMAINDER 88);
ALTER TABLE NewEvents_0088 SET (fillfactor = 70);
ALTER TABLE NewEvents_0088 SET (autovacuum_vacuum_scale_factor = 0.05, autovacuum_vacuum_threshold = 5000, autovacuum_analyze_scale_factor = 0.05, autovacuum_analyze_threshold = 2000);

CREATE TABLE IF NOT EXISTS NewEvents_0089 PARTITION OF NewEvents FOR VALUES WITH (MODULUS 128, REMAINDER 89);
ALTER TABLE NewEvents_0089 SET (fillfactor = 70);
ALTER TABLE NewEvents_0089 SET (autovacuum_vacuum_scale_factor = 0.05, autovacuum_vacuum_threshold = 5000, autovacuum_analyze_scale_factor = 0.05, autovacuum_analyze_threshold = 2000);

CREATE TABLE IF NOT EXISTS NewEvents_0090 PARTITION OF NewEvents FOR VALUES WITH (MODULUS 128, REMAINDER 90);
ALTER TABLE NewEvents_0090 SET (fillfactor = 70);
ALTER TABLE NewEvents_0090 SET (autovacuum_vacuum_scale_factor = 0.05, autovacuum_vacuum_threshold = 5000, autovacuum_analyze_scale_factor = 0.05, autovacuum_analyze_threshold = 2000);

CREATE TABLE IF NOT EXISTS NewEvents_0091 PARTITION OF NewEvents FOR VALUES WITH (MODULUS 128, REMAINDER 91);
ALTER TABLE NewEvents_0091 SET (fillfactor = 70);
ALTER TABLE NewEvents_0091 SET (autovacuum_vacuum_scale_factor = 0.05, autovacuum_vacuum_threshold = 5000, autovacuum_analyze_scale_factor = 0.05, autovacuum_analyze_threshold = 2000);

CREATE TABLE IF NOT EXISTS NewEvents_0092 PARTITION OF NewEvents FOR VALUES WITH (MODULUS 128, REMAINDER 92);
ALTER TABLE NewEvents_0092 SET (fillfactor = 70);
ALTER TABLE NewEvents_0092 SET (autovacuum_vacuum_scale_factor = 0.05, autovacuum_vacuum_threshold = 5000, autovacuum_analyze_scale_factor = 0.05, autovacuum_analyze_threshold = 2000);

CREATE TABLE IF NOT EXISTS NewEvents_0093 PARTITION OF NewEvents FOR VALUES WITH (MODULUS 128, REMAINDER 93);
ALTER TABLE NewEvents_0093 SET (fillfactor = 70);
ALTER TABLE NewEvents_0093 SET (autovacuum_vacuum_scale_factor = 0.05, autovacuum_vacuum_threshold = 5000, autovacuum_analyze_scale_factor = 0.05, autovacuum_analyze_threshold = 2000);

CREATE TABLE IF NOT EXISTS NewEvents_0094 PARTITION OF NewEvents FOR VALUES WITH (MODULUS 128, REMAINDER 94);
ALTER TABLE NewEvents_0094 SET (fillfactor = 70);
ALTER TABLE NewEvents_0094 SET (autovacuum_vacuum_scale_factor = 0.05, autovacuum_vacuum_threshold = 5000, autovacuum_analyze_scale_factor = 0.05, autovacuum_analyze_threshold = 2000);

CREATE TABLE IF NOT EXISTS NewEvents_0095 PARTITION OF NewEvents FOR VALUES WITH (MODULUS 128, REMAINDER 95);
ALTER TABLE NewEvents_0095 SET (fillfactor = 70);
ALTER TABLE NewEvents_0095 SET (autovacuum_vacuum_scale_factor = 0.05, autovacuum_vacuum_threshold = 5000, autovacuum_analyze_scale_factor = 0.05, autovacuum_analyze_threshold = 2000);

CREATE TABLE IF NOT EXISTS NewEvents_0096 PARTITION OF NewEvents FOR VALUES WITH (MODULUS 128, REMAINDER 96);
ALTER TABLE NewEvents_0096 SET (fillfactor = 70);
ALTER TABLE NewEvents_0096 SET (autovacuum_vacuum_scale_factor = 0.05, autovacuum_vacuum_threshold = 5000, autovacuum_analyze_scale_factor = 0.05, autovacuum_analyze_threshold = 2000);

CREATE TABLE IF NOT EXISTS NewEvents_0097 PARTITION OF NewEvents FOR VALUES WITH (MODULUS 128, REMAINDER 97);
ALTER TABLE NewEvents_0097 SET (fillfactor = 70);
ALTER TABLE NewEvents_0097 SET (autovacuum_vacuum_scale_factor = 0.05, autovacuum_vacuum_threshold = 5000, autovacuum_analyze_scale_factor = 0.05, autovacuum_analyze_threshold = 2000);

CREATE TABLE IF NOT EXISTS NewEvents_0098 PARTITION OF NewEvents FOR VALUES WITH (MODULUS 128, REMAINDER 98);
ALTER TABLE NewEvents_0098 SET (fillfactor = 70);
ALTER TABLE NewEvents_0098 SET (autovacuum_vacuum_scale_factor = 0.05, autovacuum_vacuum_threshold = 5000, autovacuum_analyze_scale_factor = 0.05, autovacuum_analyze_threshold = 2000);

CREATE TABLE IF NOT EXISTS NewEvents_0099 PARTITION OF NewEvents FOR VALUES WITH (MODULUS 128, REMAINDER 99);
ALTER TABLE NewEvents_0099 SET (fillfactor = 70);
ALTER TABLE NewEvents_0099 SET (autovacuum_vacuum_scale_factor = 0.05, autovacuum_vacuum_threshold = 5000, autovacuum_analyze_scale_factor = 0.05, autovacuum_analyze_threshold = 2000);

CREATE TABLE IF NOT EXISTS NewEvents_0100 PARTITION OF NewEvents FOR VALUES WITH (MODULUS 128, REMAINDER 100);
ALTER TABLE NewEvents_0100 SET (fillfactor = 70);
ALTER TABLE NewEvents_0100 SET (autovacuum_vacuum_scale_factor = 0.05, autovacuum_vacuum_threshold = 5000, autovacuum_analyze_scale_factor = 0.05, autovacuum_analyze_threshold = 2000);

CREATE TABLE IF NOT EXISTS NewEvents_0101 PARTITION OF NewEvents FOR VALUES WITH (MODULUS 128, REMAINDER 101);
ALTER TABLE NewEvents_0101 SET (fillfactor = 70);
ALTER TABLE NewEvents_0101 SET (autovacuum_vacuum_scale_factor = 0.05, autovacuum_vacuum_threshold = 5000, autovacuum_analyze_scale_factor = 0.05, autovacuum_analyze_threshold = 2000);

CREATE TABLE IF NOT EXISTS NewEvents_0102 PARTITION OF NewEvents FOR VALUES WITH (MODULUS 128, REMAINDER 102);
ALTER TABLE NewEvents_0102 SET (fillfactor = 70);
ALTER TABLE NewEvents_0102 SET (autovacuum_vacuum_scale_factor = 0.05, autovacuum_vacuum_threshold = 5000, autovacuum_analyze_scale_factor = 0.05, autovacuum_analyze_threshold = 2000);

CREATE TABLE IF NOT EXISTS NewEvents_0103 PARTITION OF NewEvents FOR VALUES WITH (MODULUS 128, REMAINDER 103);
ALTER TABLE NewEvents_0103 SET (fillfactor = 70);
ALTER TABLE NewEvents_0103 SET (autovacuum_vacuum_scale_factor = 0.05, autovacuum_vacuum_threshold = 5000, autovacuum_analyze_scale_factor = 0.05, autovacuum_analyze_threshold = 2000);

CREATE TABLE IF NOT EXISTS NewEvents_0104 PARTITION OF NewEvents FOR VALUES WITH (MODULUS 128, REMAINDER 104);
ALTER TABLE NewEvents_0104 SET (fillfactor = 70);
ALTER TABLE NewEvents_0104 SET (autovacuum_vacuum_scale_factor = 0.05, autovacuum_vacuum_threshold = 5000, autovacuum_analyze_scale_factor = 0.05, autovacuum_analyze_threshold = 2000);

CREATE TABLE IF NOT EXISTS NewEvents_0105 PARTITION OF NewEvents FOR VALUES WITH (MODULUS 128, REMAINDER 105);
ALTER TABLE NewEvents_0105 SET (fillfactor = 70);
ALTER TABLE NewEvents_0105 SET (autovacuum_vacuum_scale_factor = 0.05, autovacuum_vacuum_threshold = 5000, autovacuum_analyze_scale_factor = 0.05, autovacuum_analyze_threshold = 2000);

CREATE TABLE IF NOT EXISTS NewEvents_0106 PARTITION OF NewEvents FOR VALUES WITH (MODULUS 128, REMAINDER 106);
ALTER TABLE NewEvents_0106 SET (fillfactor = 70);
ALTER TABLE NewEvents_0106 SET (autovacuum_vacuum_scale_factor = 0.05, autovacuum_vacuum_threshold = 5000, autovacuum_analyze_scale_factor = 0.05, autovacuum_analyze_threshold = 2000);

CREATE TABLE IF NOT EXISTS NewEvents_0107 PARTITION OF NewEvents FOR VALUES WITH (MODULUS 128, REMAINDER 107);
ALTER TABLE NewEvents_0107 SET (fillfactor = 70);
ALTER TABLE NewEvents_0107 SET (autovacuum_vacuum_scale_factor = 0.05, autovacuum_vacuum_threshold = 5000, autovacuum_analyze_scale_factor = 0.05, autovacuum_analyze_threshold = 2000);

CREATE TABLE IF NOT EXISTS NewEvents_0108 PARTITION OF NewEvents FOR VALUES WITH (MODULUS 128, REMAINDER 108);
ALTER TABLE NewEvents_0108 SET (fillfactor = 70);
ALTER TABLE NewEvents_0108 SET (autovacuum_vacuum_scale_factor = 0.05, autovacuum_vacuum_threshold = 5000, autovacuum_analyze_scale_factor = 0.05, autovacuum_analyze_threshold = 2000);

CREATE TABLE IF NOT EXISTS NewEvents_0109 PARTITION OF NewEvents FOR VALUES WITH (MODULUS 128, REMAINDER 109);
ALTER TABLE NewEvents_0109 SET (fillfactor = 70);
ALTER TABLE NewEvents_0109 SET (autovacuum_vacuum_scale_factor = 0.05, autovacuum_vacuum_threshold = 5000, autovacuum_analyze_scale_factor = 0.05, autovacuum_analyze_threshold = 2000);

CREATE TABLE IF NOT EXISTS NewEvents_0110 PARTITION OF NewEvents FOR VALUES WITH (MODULUS 128, REMAINDER 110);
ALTER TABLE NewEvents_0110 SET (fillfactor = 70);
ALTER TABLE NewEvents_0110 SET (autovacuum_vacuum_scale_factor = 0.05, autovacuum_vacuum_threshold = 5000, autovacuum_analyze_scale_factor = 0.05, autovacuum_analyze_threshold = 2000);

CREATE TABLE IF NOT EXISTS NewEvents_0111 PARTITION OF NewEvents FOR VALUES WITH (MODULUS 128, REMAINDER 111);
ALTER TABLE NewEvents_0111 SET (fillfactor = 70);
ALTER TABLE NewEvents_0111 SET (autovacuum_vacuum_scale_factor = 0.05, autovacuum_vacuum_threshold = 5000, autovacuum_analyze_scale_factor = 0.05, autovacuum_analyze_threshold = 2000);

CREATE TABLE IF NOT EXISTS NewEvents_0112 PARTITION OF NewEvents FOR VALUES WITH (MODULUS 128, REMAINDER 112);
ALTER TABLE NewEvents_0112 SET (fillfactor = 70);
ALTER TABLE NewEvents_0112 SET (autovacuum_vacuum_scale_factor = 0.05, autovacuum_vacuum_threshold = 5000, autovacuum_analyze_scale_factor = 0.05, autovacuum_analyze_threshold = 2000);

CREATE TABLE IF NOT EXISTS NewEvents_0113 PARTITION OF NewEvents FOR VALUES WITH (MODULUS 128, REMAINDER 113);
ALTER TABLE NewEvents_0113 SET (fillfactor = 70);
ALTER TABLE NewEvents_0113 SET (autovacuum_vacuum_scale_factor = 0.05, autovacuum_vacuum_threshold = 5000, autovacuum_analyze_scale_factor = 0.05, autovacuum_analyze_threshold = 2000);

CREATE TABLE IF NOT EXISTS NewEvents_0114 PARTITION OF NewEvents FOR VALUES WITH (MODULUS 128, REMAINDER 114);
ALTER TABLE NewEvents_0114 SET (fillfactor = 70);
ALTER TABLE NewEvents_0114 SET (autovacuum_vacuum_scale_factor = 0.05, autovacuum_vacuum_threshold = 5000, autovacuum_analyze_scale_factor = 0.05, autovacuum_analyze_threshold = 2000);

CREATE TABLE IF NOT EXISTS NewEvents_0115 PARTITION OF NewEvents FOR VALUES WITH (MODULUS 128, REMAINDER 115);
ALTER TABLE NewEvents_0115 SET (fillfactor = 70);
ALTER TABLE NewEvents_0115 SET (autovacuum_vacuum_scale_factor = 0.05, autovacuum_vacuum_threshold = 5000, autovacuum_analyze_scale_factor = 0.05, autovacuum_analyze_threshold = 2000);

CREATE TABLE IF NOT EXISTS NewEvents_0116 PARTITION OF NewEvents FOR VALUES WITH (MODULUS 128, REMAINDER 116);
ALTER TABLE NewEvents_0116 SET (fillfactor = 70);
ALTER TABLE NewEvents_0116 SET (autovacuum_vacuum_scale_factor = 0.05, autovacuum_vacuum_threshold = 5000, autovacuum_analyze_scale_factor = 0.05, autovacuum_analyze_threshold = 2000);

CREATE TABLE IF NOT EXISTS NewEvents_0117 PARTITION OF NewEvents FOR VALUES WITH (MODULUS 128, REMAINDER 117);
ALTER TABLE NewEvents_0117 SET (fillfactor = 70);
ALTER TABLE NewEvents_0117 SET (autovacuum_vacuum_scale_factor = 0.05, autovacuum_vacuum_threshold = 5000, autovacuum_analyze_scale_factor = 0.05, autovacuum_analyze_threshold = 2000);

CREATE TABLE IF NOT EXISTS NewEvents_0118 PARTITION OF NewEvents FOR VALUES WITH (MODULUS 128, REMAINDER 118);
ALTER TABLE NewEvents_0118 SET (fillfactor = 70);
ALTER TABLE NewEvents_0118 SET (autovacuum_vacuum_scale_factor = 0.05, autovacuum_vacuum_threshold = 5000, autovacuum_analyze_scale_factor = 0.05, autovacuum_analyze_threshold = 2000);

CREATE TABLE IF NOT EXISTS NewEvents_0119 PARTITION OF NewEvents FOR VALUES WITH (MODULUS 128, REMAINDER 119);
ALTER TABLE NewEvents_0119 SET (fillfactor = 70);
ALTER TABLE NewEvents_0119 SET (autovacuum_vacuum_scale_factor = 0.05, autovacuum_vacuum_threshold = 5000, autovacuum_analyze_scale_factor = 0.05, autovacuum_analyze_threshold = 2000);

CREATE TABLE IF NOT EXISTS NewEvents_0120 PARTITION OF NewEvents FOR VALUES WITH (MODULUS 128, REMAINDER 120);
ALTER TABLE NewEvents_0120 SET (fillfactor = 70);
ALTER TABLE NewEvents_0120 SET (autovacuum_vacuum_scale_factor = 0.05, autovacuum_vacuum_threshold = 5000, autovacuum_analyze_scale_factor = 0.05, autovacuum_analyze_threshold = 2000);

CREATE TABLE IF NOT EXISTS NewEvents_0121 PARTITION OF NewEvents FOR VALUES WITH (MODULUS 128, REMAINDER 121);
ALTER TABLE NewEvents_0121 SET (fillfactor = 70);
ALTER TABLE NewEvents_0121 SET (autovacuum_vacuum_scale_factor = 0.05, autovacuum_vacuum_threshold = 5000, autovacuum_analyze_scale_factor = 0.05, autovacuum_analyze_threshold = 2000);

CREATE TABLE IF NOT EXISTS NewEvents_0122 PARTITION OF NewEvents FOR VALUES WITH (MODULUS 128, REMAINDER 122);
ALTER TABLE NewEvents_0122 SET (fillfactor = 70);
ALTER TABLE NewEvents_0122 SET (autovacuum_vacuum_scale_factor = 0.05, autovacuum_vacuum_threshold = 5000, autovacuum_analyze_scale_factor = 0.05, autovacuum_analyze_threshold = 2000);

CREATE TABLE IF NOT EXISTS NewEvents_0123 PARTITION OF NewEvents FOR VALUES WITH (MODULUS 128, REMAINDER 123);
ALTER TABLE NewEvents_0123 SET (fillfactor = 70);
ALTER TABLE NewEvents_0123 SET (autovacuum_vacuum_scale_factor = 0.05, autovacuum_vacuum_threshold = 5000, autovacuum_analyze_scale_factor = 0.05, autovacuum_analyze_threshold = 2000);

CREATE TABLE IF NOT EXISTS NewEvents_0124 PARTITION OF NewEvents FOR VALUES WITH (MODULUS 128, REMAINDER 124);
ALTER TABLE NewEvents_0124 SET (fillfactor = 70);
ALTER TABLE NewEvents_0124 SET (autovacuum_vacuum_scale_factor = 0.05, autovacuum_vacuum_threshold = 5000, autovacuum_analyze_scale_factor = 0.05, autovacuum_analyze_threshold = 2000);

CREATE TABLE IF NOT EXISTS NewEvents_0125 PARTITION OF NewEvents FOR VALUES WITH (MODULUS 128, REMAINDER 125);
ALTER TABLE NewEvents_0125 SET (fillfactor = 70);
ALTER TABLE NewEvents_0125 SET (autovacuum_vacuum_scale_factor = 0.05, autovacuum_vacuum_threshold = 5000, autovacuum_analyze_scale_factor = 0.05, autovacuum_analyze_threshold = 2000);

CREATE TABLE IF NOT EXISTS NewEvents_0126 PARTITION OF NewEvents FOR VALUES WITH (MODULUS 128, REMAINDER 126);
ALTER TABLE NewEvents_0126 SET (fillfactor = 70);
ALTER TABLE NewEvents_0126 SET (autovacuum_vacuum_scale_factor = 0.05, autovacuum_vacuum_threshold = 5000, autovacuum_analyze_scale_factor = 0.05, autovacuum_analyze_threshold = 2000);

CREATE TABLE IF NOT EXISTS NewEvents_0127 PARTITION OF NewEvents FOR VALUES WITH (MODULUS 128, REMAINDER 127);
ALTER TABLE NewEvents_0127 SET (fillfactor = 70);
ALTER TABLE NewEvents_0127 SET (autovacuum_vacuum_scale_factor = 0.05, autovacuum_vacuum_threshold = 5000, autovacuum_analyze_scale_factor = 0.05, autovacuum_analyze_threshold = 2000);

-- ============================================================================
-- NewTasks Table (single table, no partitioning)
-- ============================================================================
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

CREATE INDEX IF NOT EXISTS IX_NewTasks_ID_SeqNum ON NewTasks(InstanceID, SequenceNumber);