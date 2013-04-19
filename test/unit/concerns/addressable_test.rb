require "minitest_helper"

class WannabeAddressable
  extend Cms::Concerns::CanBeAddressable
end

class CouldBeAddressable < ActiveRecord::Base; end

class HasSelfDefinedPath < ActiveRecord::Base
  is_addressable(no_dynamic_path: true)
  attr_accessible :path
end

class IsAddressable < ActiveRecord::Base;
  is_addressable path: "/widgets"
end

describe Cms::Concerns::Addressable do

  def create_testing_table(name, &block)
    ActiveRecord::Base.connection.instance_eval do
      drop_table(name) if table_exists?(name)
      create_table(name, &block)
    end
  end

  before :all do
    create_testing_table :is_addressables do |t|
      t.string :name
      t.string :slug
    end
    create_testing_table :has_self_defined_paths do |t|
      t.string :path
    end
  end

  let(:addressable) { IsAddressable.new }
  describe '#is_addressable' do
    it "should have parent relationship" do
      WannabeAddressable.expects(:attr_accessible).with(:parent)
      WannabeAddressable.expects(:has_one)
      WannabeAddressable.is_addressable
      WannabeAddressable.new.must_respond_to :parent
    end

    it "should be added to all ActiveRecord classes" do
      CouldBeAddressable.must_respond_to :is_addressable
    end

    it "provide default path where instances will be placed" do
      IsAddressable.path.must_equal "/widgets"
    end

    it "should allow :path to be ActiveRecord::Base attribute" do
      p = HasSelfDefinedPath.new(path: "/custom")
      p.path.must_equal "/custom"
    end
  end

  describe "#can_have_parent?" do
    it "should be false for non-addressable blocks" do
      WannabeAddressable.can_have_parent?.must_equal false
    end

    it "should be true for addressable block" do
      IsAddressable.can_have_parent?.must_equal true
    end
  end

  describe ".path" do

    it "should join #path and .slug" do
      addressable.slug = "one"
      addressable.path.must_equal "/widgets/one"
    end
  end

  describe "#calculate_path" do
    it "should generate the correct path given a slug" do
      IsAddressable.calculate_path("slug").must_equal "/widgets/slug"
    end
  end

  describe ".page_title" do
    it "should default to the name" do
      addressable.name = "Some Name"
      addressable.page_title.must_equal "Some Name"
    end

  end
end