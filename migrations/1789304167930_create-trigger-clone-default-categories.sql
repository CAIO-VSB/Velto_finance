CREATE OR REPLACE FUNCTION clone_default_categories()
RETURNS TRIGGER AS $$
BEGIN
    INSERT INTO categories (user_id, name_identifier, url_icon, active, type_categorie)
    SELECT NEW.id, name_identifier, url_icon, true, type_categorie
    FROM default_categories;
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;


CREATE TRIGGER trg_clone_default_categories
AFTER INSERT ON "user"
FOR EACH ROW
EXECUTE FUNCTION clone_default_categories();