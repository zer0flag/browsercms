require File.dirname(__FILE__) + '/../../spec_helper'

ActiveRecord::Base.connection.instance_eval do
  drop_table(:attachables) if table_exists?(:attachables)
  create_table(:attachables) do |t| 
    t.string :name
    t.integer :attachment_id
    t.integer :attachment_version
  end

  drop_table(:versioned_attachables) if table_exists?(:versioned_attachables)
  drop_table(:versioned_attachable_versions) if table_exists?(:versioned_attachable_versions)
  create_versioned_table(:versioned_attachables) do |t| 
    t.string :name
    t.integer :attachment_id
    t.integer :attachment_version
  end
end

class Attachable < ActiveRecord::Base
  belongs_to_attachment
end

class VersionedAttachable < ActiveRecord::Base
  acts_as_content_block :belongs_to_attachment => true
end

describe HtmlBlock do
  it "should not belong to an attachment" do
    HtmlBlock.belongs_to_attachment?.should be_false
  end
end

describe Attachable do
  it "should belong to an attachment" do
    Attachable.belongs_to_attachment?.should be_true
  end
  describe "file name sanitization" do
    {
      "Draft #1.txt" => "Draft_1.txt",
      "Copy of 100% of Paul's Time(1).txt" => "Copy_of_100_of_Pauls_Time-1-.txt"
    }.each do |example, expected|
      it("should convert '#{example}' to '#{expected}'") do
        Attachable.new.sanitize_file_name(example).should == expected
      end
    end
  end
  describe "creating" do
    before do
      #file is a mock of the object that Rails wraps file uploads in
      @file = mock("file", :original_filename => "foo.jpg",
        :content_type => "image/jpeg", :rewind => true,
        :size => "99", :read => "01010010101010101")

      @section = create_section(:name => "attachables", :parent => root_section)      
    end
    describe "with an attachment section ID, attachment file and attachment file name" do
      before do
        @attachable = Attachable.new(:name => "Section ID, File and File Name", 
          :attachment_section_id => @section.id, 
          :attachment_file => @file, 
          :attachment_file_name => "test.jpg")
        @saving_the_attachable = lambda { @attachable.save.should be_true }
      end
      it "should change the attachable count by 1" do
        @saving_the_attachable.should change(Attachable, :count).by(1)
      end
      describe "once it has been saved" do
        before do
          @saving_the_attachable.call
        end
        it "should set the attachment section" do
          @attachable.attachment_section.should == @section
        end
        it "should set the attachment section id" do
          @attachable.attachment_section_id.should == @section.id
        end
        it "should set the attachment file name" do
          @attachable.attachment_file_name.should == "/test.jpg"
        end
      end
      describe "once it has been saved and reloaded" do
        before do
          @saving_the_attachable.call
          reset(:attachable)
        end
        it "should set the attachment section" do
          @attachable.attachment_section.should == @section
        end
        it "should set the attachment section id" do
          @attachable.attachment_section_id.should == @section.id
        end
        it "should set the attachment file name" do
          @attachable.attachment_file_name.should == "/test.jpg"
        end
      end      
    end
    describe "with an attachment section, attachment file and attachment file name" do
      before do
        @attachable = Attachable.new(:name => "Section, File and File Name", 
          :attachment_section => @section, 
          :attachment_file => @file, 
          :attachment_file_name => "test.jpg")
        @saving_the_attachable = lambda { @attachable.save.should be_true }
      end
      it "should change the attachable count by 1" do
        @saving_the_attachable.should change(Attachable, :count).by(1)
      end
      describe "once it has been saved" do
        before do
          @saving_the_attachable.call
        end
        it "should set the attachment section" do
          @attachable.attachment_section.should == @section
        end
        it "should set the attachment section id" do
          @attachable.attachment_section_id.should == @section.id
        end
        it "should set the attachment file name" do
          @attachable.attachment_file_name.should == "/test.jpg"
        end
      end
      describe "once it has been saved and reloaded" do
        before do
          @saving_the_attachable.call
          reset(:attachable)
        end
        it "should set the attachment section" do
          @attachable.attachment_section.should == @section
        end
        it "should set the attachment section id" do
          @attachable.attachment_section_id.should == @section.id
        end
        it "should set the attachment file name" do
          @attachable.attachment_file_name.should == "/test.jpg"
        end
      end      
    end
    describe "with an attachment section but no attachment file" do
      before do
        @attachable = Attachable.new(:name => "Section, No File", 
          :attachment_section => @section)
        @saving_the_attachable = lambda { @attachable.save.should be_false }
      end
      it "should not change the attachable count" do
        @saving_the_attachable.should_not change(Attachable, :count)
      end
      it "should not be valid" do
        @attachable.should_not be_valid
      end
      describe "once it has been saved" do
        before do
          @saving_the_attachable.call
        end
        it "should set the attachment section" do
          @attachable.attachment_section.should == @section
        end
        it "should set the attachment section id" do
          @attachable.attachment_section_id.should == @section.id
        end
        it "should have nil for an attachment file name" do
          @attachable.attachment_file_name.should be_nil
        end
      end
    end
    describe "with an attachment section but no attachment file" do
      before do
        @attachable = Attachable.new(:name => "File Name, No File", 
          :attachment_file_name => "whatever.jpg")
        @saving_the_attachable = lambda { @attachable.save.should be_false }
      end
      it "should not change the attachable count" do
        @saving_the_attachable.should_not change(Attachable, :count)
      end
      it "should not be valid" do
        @attachable.should_not be_valid
      end
      describe "once it has been saved" do
        before do
          @saving_the_attachable.call
        end
        it "should set the attachment section to nil" do
          @attachable.attachment_section.should be_nil
        end
        it "should set the attachment section id to nil" do
          @attachable.attachment_section_id.should be_nil
        end
        it "should have nil for an attachment file name" do
          @attachable.attachment_file_name.should == "whatever.jpg"
        end
      end
    end
    describe "with a screwy attachment file name" do
      before do
        @attachable = Attachable.new(:name => "Section ID, File and File Name", 
          :attachment_section_id => @section.id, 
          :attachment_file => @file, 
          :attachment_file_name => "Broken? Yes & No!.txt")
        @saving_the_attachable = lambda { @attachable.save.should be_true }    
      end
      it "should change the attachable count by 1" do
        @saving_the_attachable.should change(Attachable, :count).by(1)
      end
      describe "after saving" do
        before { @saving_the_attachable.call }
        it "should sanitize the file name" do
          @attachable.attachment_file_name.should == "/Broken_Yes_-_No.txt"
        end
      end        
    end
  end
  describe "updating the attachment file name" do
    before do
      #file is a mock of the object that Rails wraps file uploads in
      @file = mock("file", :original_filename => "foo.jpg",
        :content_type => "image/jpeg", :rewind => true,
        :size => "99", :read => "01010010101010101")

      @section = create_section(:name => "attachables", :parent => root_section)      
    
      @attachable = Attachable.create!(:name => "Foo", 
        :attachment_section_id => @section.id, 
        :attachment_file => @file, 
        :attachment_file_name => "test.jpg")
      reset(:attachable)
      @updating_the_attachable = lambda { @attachable.update_attributes(:attachment_file_name => "test2.jpg") }
    end
    it "should not create a new attachment" do
      @updating_the_attachable.should_not change(Attachment, :count)
    end
    it "should create a new version of the attachment" do
      @updating_the_attachable.should change(Attachment::Version, :count).by(1)
    end
    it "should update the attachment file name" do
      @updating_the_attachable.call
      @attachable.attachment_file_name.should == "/test2.jpg"
      reset(:attachable)
      @attachable.attachment_file_name.should == "/test2.jpg"
    end
    it "should update the attachment version" do
      @updating_the_attachable.should change(@attachable, :attachment_version).by(1)
    end
  end
end
