#!/usr/bin/env ruby

require File.dirname(__FILE__) + '/../../spec_helper'

require 'puppet/file_serving/file_base'

describe Puppet::FileServing::FileBase, " when initializing" do
    it "should accept a key in the form of a URI" do
        Puppet::FileServing::FileBase.new("puppet://host/module/dir/file").key.should == "puppet://host/module/dir/file"
    end

    it "should allow specification of whether links should be managed" do
        Puppet::FileServing::FileBase.new("puppet://host/module/dir/file", :links => :manage).links.should == :manage
    end

    it "should fail if :links is set to anything other than :manage or :follow" do
        proc { Puppet::FileServing::FileBase.new("puppet://host/module/dir/file", :links => :else) }.should raise_error(ArgumentError)
    end

    it "should default to :manage for :links" do
        Puppet::FileServing::FileBase.new("puppet://host/module/dir/file").links.should == :manage
    end

    it "should allow specification of a path" do
        FileTest.stubs(:exists?).returns(true)
        Puppet::FileServing::FileBase.new("puppet://host/module/dir/file", :path => "/my/file").path.should == "/my/file"
    end

    it "should allow specification of a relative path" do
        FileTest.stubs(:exists?).returns(true)
        Puppet::FileServing::FileBase.new("puppet://host/module/dir/file", :relative_path => "my/file").relative_path.should == "my/file"
    end
end

describe Puppet::FileServing::FileBase, " when setting the base path" do
    before do
        @file = Puppet::FileServing::FileBase.new("puppet://host/module/dir/file")
    end

    it "should require that the base path be fully qualified" do
        FileTest.stubs(:exists?).returns(true)
        proc { @file.path = "unqualified/file" }.should raise_error(ArgumentError)
    end
end

describe Puppet::FileServing::FileBase, " when setting the relative path" do
    it "should require that the relative path be unqualified" do
        @file = Puppet::FileServing::FileBase.new("puppet://host/module/dir/file")
        FileTest.stubs(:exists?).returns(true)
        proc { @file.relative_path = "/qualified/file" }.should raise_error(ArgumentError)
    end
end

describe Puppet::FileServing::FileBase, " when determining the full file path" do
    before do
        @file = Puppet::FileServing::FileBase.new("mykey", :path => "/this/file")
    end

    it "should return the path if there is no relative path" do
        @file.full_path.should == "/this/file"
    end

    it "should return the path joined with the relative path if there is a relative path" do
        @file.relative_path = "not/qualified"
        @file.full_path.should == "/this/file/not/qualified"
    end

    it "should should fail if there is no path set" do
        @file = Puppet::FileServing::FileBase.new("not/qualified")
        proc { @file.full_path }.should raise_error(ArgumentError)
    end
end

describe Puppet::FileServing::FileBase, " when stat'ing files" do
    before do
        @file = Puppet::FileServing::FileBase.new("mykey", :path => "/this/file")
    end

    it "should stat the file's full path" do
        @file.stubs(:full_path).returns("/this/file")
        File.expects(:lstat).with("/this/file").returns stub("stat", :ftype => "file")
        @file.stat
    end

    it "should fail if the file does not exist" do
        @file.stubs(:full_path).returns("/this/file")
        File.expects(:lstat).with("/this/file").raises(Errno::ENOENT)
        proc { @file.stat }.should raise_error(Errno::ENOENT)
    end

    it "should use :lstat if :links is set to :manage" do
        File.expects(:lstat).with("/this/file").returns stub("stat", :ftype => "file")
        @file.stat
    end

    it "should use :stat if :links is set to :follow" do
        File.expects(:stat).with("/this/file").returns stub("stat", :ftype => "file")
        @file.links = :follow
        @file.stat
    end
end
