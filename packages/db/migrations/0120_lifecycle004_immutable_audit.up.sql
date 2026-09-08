-- LIFECYCLE-004-FIX: lifecycle financial audit survives permanently.
CREATE FUNCTION prevent_financial_lifecycle_audit_mutation()
RETURNS TRIGGER AS $$ BEGIN
    IF OLD.action IN ('contest.remove_participant','contest.cancelled') THEN
        RAISE EXCEPTION 'financial lifecycle audit rows are append-only';
    END IF;
    RETURN CASE WHEN TG_OP = 'DELETE' THEN OLD ELSE NEW END;
END; $$ LANGUAGE plpgsql;

CREATE TRIGGER financial_lifecycle_audit_append_only
    BEFORE UPDATE OR DELETE ON audit_logs
    FOR EACH ROW EXECUTE FUNCTION prevent_financial_lifecycle_audit_mutation();

