RSpec.describe RavenDB::QueryBuilder, rdbc_88: true do
  it "can understand equality" do
    query = store
            .open_session
            .query(collection: "Users")
            .where_equals("Name", "red")

    index_query = query.get_index_query

    expect(index_query.query).to eq("from Users where Name = $p0")
    expect(index_query.query_parameters[:p0]).to eq("red")
  end

  it "can understand exact equality" do
    query = store
            .open_session
            .query(index_name: "IndexName")
            .where_equals("Name", "ayende", true)

    index_query = query.get_index_query

    expect(index_query.query).to eq("from index 'IndexName' where exact(Name = $p0)")
    expect(index_query.query_parameters[:p0]).to eq("ayende")
  end

  it "can understand equal on date" do
    date_time = DateTime.strptime("2010-05-15T00:00:00", "%Y-%m-%dT%H:%M:%S")

    query = store
            .open_session
            .query(index_name: "IndexName")
            .where_equals("Birthday", date_time)

    index_query = query.get_index_query

    expect(index_query.query).to eq("from index 'IndexName' where Birthday = $p0")
    expect(index_query.query_parameters[:p0]).to eq("2010-05-15T00:00:00.0000000")
  end

  it "can understand equal on bool" do
    query = store
            .open_session
            .query(collection: "Users")
            .where_equals("Active", false)

    index_query = query.get_index_query

    expect(index_query.query).to eq("from Users where Active = $p0")
    expect(index_query.query_parameters[:p0]).to be(false)
  end

  it "can understand not equal" do
    query = store
            .open_session
            .query(collection: "Users")
            .where_not_equals("Active", false)

    index_query = query.get_index_query

    expect(index_query.query).to eq("from Users where Active != $p0")
    expect(index_query.query_parameters[:p0]).to be(false)
  end

  it "can understand in" do
    query = store
            .open_session
            .query(index_name: "IndexName")
            .where_in("Name", ["ryan", "heath"])

    index_query = query.get_index_query

    expect(index_query.query).to eq("from index 'IndexName' where Name in ($p0)")
    expect(index_query.query_parameters[:p0]).to eq(["ryan", "heath"])
  end

  it "no conditions should produce empty where" do
    query = store
            .open_session
            .query(index_name: "IndexName")

    index_query = query.get_index_query

    expect(index_query.query).to eq("from index 'IndexName'")
  end

  it "can understand and" do
    query = store
            .open_session
            .query(index_name: "IndexName")
            .where_equals("Name", "ayende")
            .and_also
            .where_equals("Email", "ayende@ayende.com")

    index_query = query.get_index_query

    expect(index_query.query).to eq("from index 'IndexName' where Name = $p0 and Email = $p1")
    expect(index_query.query_parameters[:p0]).to eq("ayende")
    expect(index_query.query_parameters[:p1]).to eq("ayende@ayende.com")
  end

  it "can understand or" do
    query = store
            .open_session
            .query(index_name: "IndexName")
            .where_equals("Name", "ayende")
            .or_else.where_equals("Email", "ayende@ayende.com")

    index_query = query.get_index_query

    expect(index_query.query).to eq("from index 'IndexName' where Name = $p0 or Email = $p1")
    expect(index_query.query_parameters[:p0]).to eq("ayende")
    expect(index_query.query_parameters[:p1]).to eq("ayende@ayende.com")
  end

  it "can understand less than" do
    query = store
            .open_session
            .query(index_name: "IndexName")
            .where_less_than("Age", 16)

    index_query = query.get_index_query

    expect(index_query.query).to eq("from index 'IndexName' where Age < $p0")
    expect(index_query.query_parameters[:p0]).to eq(16)
  end

  it "can understand less than or equal" do
    query = store
            .open_session
            .query(index_name: "IndexName")
            .where_less_than_or_equal("Age", 16)

    index_query = query.get_index_query

    expect(index_query.query).to eq("from index 'IndexName' where Age <= $p0")
    expect(index_query.query_parameters[:p0]).to eq(16)
  end

  it "can understand greater than" do
    query = store
            .open_session
            .query(index_name: "IndexName").where_greater_than("Age", 16)

    index_query = query.get_index_query

    expect(index_query.query).to eq("from index 'IndexName' where Age > $p0")
    expect(index_query.query_parameters[:p0]).to eq(16)
  end

  it "can understand greater than or equal" do
    query = store
            .open_session
            .query(index_name: "IndexName")
            .where_greater_than_or_equal("Age", 16)

    index_query = query.get_index_query

    expect(index_query.query).to eq("from index 'IndexName' where Age >= $p0")
    expect(index_query.query_parameters[:p0]).to eq(16)
  end

  it "can understand projection of single field" do
    query = store
            .open_session
            .query(index_name: "IndexName")
            .where_greater_than_or_equal("Age", 16)
            .select_fields(["Name"])

    index_query = query.get_index_query

    expect(index_query.query).to eq("from index 'IndexName' where Age >= $p0 select Name")
    expect(index_query.query_parameters[:p0]).to eq(16)
  end

  it "can understand projection of multiple fields" do
    query = store
            .open_session
            .query(index_name: "IndexName")
            .where_greater_than_or_equal("Age", 16)
            .select_fields(["Name", "Age"])

    index_query = query.get_index_query

    expect(index_query.query).to eq("from index 'IndexName' where Age >= $p0 select Name, Age")
    expect(index_query.query_parameters[:p0]).to eq(16)
  end

  it "can understand between" do
    min = 1224
    max = 1226

    query = store
            .open_session
            .query(collection: "IndexedUsers")
            .where_between("Rate", min, max)

    index_query = query.get_index_query

    expect(index_query.query).to eq("from IndexedUsers where Rate between $p0 and $p1")
    expect(index_query.query_parameters[:p0]).to eq(min)
    expect(index_query.query_parameters[:p1]).to eq(max)
  end

  it "can understand starts with" do
    query = store
            .open_session
            .query(collection: "Users").where_starts_with("Name", "foo")

    index_query = query.get_index_query

    expect(index_query.query).to eq("from Users where startsWith(Name, $p0)")
    expect(index_query.query_parameters[:p0]).to eq("foo")
  end

  it "can understand ends with" do
    query = store
            .open_session
            .query(collection: "Users")
            .where_ends_with("Name", "foo")

    index_query = query.get_index_query

    expect(index_query.query).to eq("from Users where endsWith(Name, $p0)")
    expect(index_query.query_parameters[:p0]).to eq("foo")
  end

  it "wraps first not with true token" do
    query = store
            .open_session
            .query(collection: "Users")
            .where_true
            .and_also
            .not.where_starts_with("Name", "foo")

    index_query = query.get_index_query

    expect(index_query.query).to eq("from Users where true and not startsWith(Name, $p0)")
    expect(index_query.query_parameters[:p0]).to eq("foo")
  end

  it "can understand subclauses" do
    query = store
            .open_session
            .query(collection: "Users")
            .where_greater_than_or_equal("Age", 16)
            .and_also
            .open_subclause
            .where_equals("Name", "rob")
            .or_else
            .where_equals("Name", "dave")
            .close_subclause

    index_query = query.get_index_query

    expect(index_query.query).to eq("from Users where Age >= $p0 and (Name = $p1 or Name = $p2)")
    expect(index_query.query_parameters[:p0]).to eq(16)
    expect(index_query.query_parameters[:p1]).to eq("rob")
    expect(index_query.query_parameters[:p2]).to eq("dave")
  end
end
