-- Incident ticket database schema
-- Simulates ServiceNow / Jira / PagerDuty incident records

CREATE TABLE IF NOT EXISTS incidents (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    incident_id TEXT UNIQUE NOT NULL,
    title TEXT NOT NULL,
    severity TEXT NOT NULL CHECK(severity IN ('P1','P2','P3','P4')),
    category TEXT NOT NULL CHECK(category IN ('Security','Infrastructure','Application','Data')),
    subcategory TEXT,
    status TEXT NOT NULL DEFAULT 'Open' CHECK(status IN ('Open','Investigating','Mitigated','Resolved','Closed')),
    affected_systems TEXT,
    root_cause TEXT,
    immediate_actions TEXT,
    assigned_team TEXT,
    escalation_contact TEXT,
    created_at TEXT NOT NULL DEFAULT (datetime('now')),
    resolved_at TEXT,
    duration_minutes INTEGER,
    source TEXT,
    notes TEXT
);

CREATE TABLE IF NOT EXISTS incident_updates (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    incident_id TEXT NOT NULL REFERENCES incidents(incident_id),
    update_text TEXT NOT NULL,
    author TEXT NOT NULL DEFAULT 'triage-bot',
    created_at TEXT NOT NULL DEFAULT (datetime('now'))
);

CREATE TABLE IF NOT EXISTS runbooks (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    category TEXT NOT NULL,
    subcategory TEXT NOT NULL,
    title TEXT NOT NULL,
    steps TEXT NOT NULL,
    last_used TEXT,
    success_rate REAL
);

-- Seed: historical incidents (so Claude can query patterns)
INSERT INTO incidents (incident_id, title, severity, category, subcategory, status, affected_systems, root_cause, assigned_team, created_at, resolved_at, duration_minutes, source) VALUES
('INC-2026-0112', 'SSH brute force from 198.51.100.23', 'P2', 'Security', 'Brute-force attack', 'Resolved', 'prod-bastion-01', 'Automated credential stuffing from compromised VPS', 'Security', '2026-03-15 08:30:00', '2026-03-15 09:15:00', 45, 'SIEM — Splunk'),
('INC-2026-0098', 'Disk critical on prod-db-primary-02', 'P1', 'Infrastructure', 'Disk exhaustion', 'Resolved', 'prod-db-primary-02, patient-records-api', 'WAL archiving failure due to network partition to archive host', 'Database', '2026-03-10 14:00:00', '2026-03-10 15:30:00', 90, 'Monitoring — Datadog'),
('INC-2026-0087', 'API latency spike on patient-service', 'P2', 'Application', 'Latency degradation', 'Resolved', 'patient-service, redis-cache-prod', 'Redis connection pool exhaustion after config change', 'Application', '2026-03-05 11:20:00', '2026-03-05 12:45:00', 85, 'Monitoring — Grafana'),
('INC-2026-0076', 'Unauthorized API key usage detected', 'P1', 'Security', 'Credential compromise', 'Resolved', 'api-gateway, patient-service', 'Leaked API key in public GitHub repo', 'Security', '2026-02-28 16:00:00', '2026-02-28 18:30:00', 150, 'SIEM — Splunk'),
('INC-2026-0065', 'Certificate expiry on api-gateway', 'P3', 'Infrastructure', 'Certificate management', 'Resolved', 'api-gateway', 'Auto-renewal failed due to DNS validation timeout', 'Infrastructure', '2026-02-20 09:00:00', '2026-02-20 10:00:00', 60, 'Monitoring — Datadog'),
('INC-2026-0054', 'Database replication lag > 30s', 'P2', 'Data', 'Replication lag', 'Resolved', 'prod-db-primary-03, prod-db-replica-01', 'Long-running analytical query on replica blocking replication', 'Database', '2026-02-15 13:45:00', '2026-02-15 14:30:00', 45, 'Monitoring — Datadog'),
('INC-2026-0043', 'Memory leak in clinical-portal', 'P3', 'Application', 'Memory leak', 'Resolved', 'clinical-portal', 'Unbounded session cache in v3.2.1', 'Application', '2026-02-10 10:00:00', '2026-02-10 16:00:00', 360, 'Monitoring — Grafana'),
('INC-2026-0032', 'DDoS on public-facing load balancer', 'P1', 'Security', 'DDoS attack', 'Resolved', 'lb-public-01, api-gateway, patient-service', 'Volumetric UDP flood from botnet', 'Security', '2026-02-01 03:00:00', '2026-02-01 05:00:00', 120, 'SIEM — Splunk');

-- Seed: runbooks
INSERT INTO runbooks (category, subcategory, title, steps, last_used, success_rate) VALUES
('Security', 'Brute-force attack', 'SSH Brute Force Response', '1. Block source IP at firewall\n2. Audit auth logs for successful logins\n3. Check for lateral movement\n4. Report to security team\n5. Add IP to threat intel feed', '2026-03-15', 0.95),
('Infrastructure', 'Disk exhaustion', 'Database Disk Critical Response', '1. Identify top disk consumers\n2. Clear safe WAL/log files\n3. Check archiving pipeline\n4. Disable debug logging if active\n5. Prepare failover if needed', '2026-03-10', 0.90),
('Application', 'Deployment failure', 'Failed Deployment Rollback', '1. Confirm rollback target version\n2. Execute rollback via CI/CD\n3. Verify health checks pass\n4. Check downstream dependencies\n5. Post-mortem on failed deploy', '2026-03-05', 0.85),
('Security', 'Credential compromise', 'API Key Rotation', '1. Revoke compromised key immediately\n2. Issue new key to legitimate consumers\n3. Audit access logs for unauthorized usage\n4. Scan for key in public repos\n5. Update key rotation policy', '2026-02-28', 1.0);
