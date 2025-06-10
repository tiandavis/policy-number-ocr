module FixtureHelper
  def fixture(name)
    File.read(File.join(File.dirname(__FILE__), '..', 'fixtures', "#{name}.txt"))
  end

  def fixture_path(name)
    File.join(File.dirname(__FILE__), '..', 'fixtures', "#{name}.txt")
  end
end 