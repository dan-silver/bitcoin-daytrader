class Database
  require "sqlite3"
  def initialize
    @db = SQLite3::Database.new "#{@name}.db"
    create_table
  end

  def create_table
    query = ""
    @columns.each do |col|
         query << "#{col[0].to_s} #{col[1]},"
    end
    query = query[0..-2]
    @db.execute "create table if not exists #{@name} ( #{query}  );"
  end

  def empty
    @db.execute "delete from #{@name}"
  end

  def all_rows
    @db.execute "select * from #{@name}"
  end
end