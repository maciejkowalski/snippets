require 'spec_helper'

describe DecreesController do
  let(:user) { create(:overseer) } # Skip CanCan.
  before(:each) { sign_in(user) }

  setup_and_teardown_tire_indexes(Decree)
  render_views

  describe '#index' do

    context "empty results" do
      it "should return correct format" do
        get :index, :format => :json
        response.should be_success
        pagination_json["num_pages"].should eql(0)
        pagination_json["current_page"].should eql(1)
        pagination_json["total_count"].should eql(0)
        results_json.should be_empty
      end
    end

    context "non empty db" do
      before(:all) do
        create_list(:decree_with_articles, 30)
        refresh_indexes(Decree)
      end
  #...
####################################################
# /spec/lib
####################################################
# encoding: utf-8
require 'spec_helper'

describe OfflineAccess do
  include OfflineMacros # import create_params helper

  subject { OfflineAccess }
  let(:file) { create(:update_file) }
  let(:user) { create(:offline_user) }
  let(:user_params) { create_params(user) }

  describe '#check_files' do

    context 'given valid filename' do
      f = FactoryGirl.create(:update_file) # HACK
      it "should return #{OfflineAPI::Responses.file_found(f.attachment_filename)}" do
        OfflineAccess.new(user_params.merge!(:filename => file.attachment_filename)).
          check_files.should eq("OK\n File found resque.zip")
      end
    end

    context 'given invalid filename' do
      it "should return #{OfflineAPI::Responses.file_not_found}" do
        OfflineAccess.new(user_params.merge!(:filename => 'pippo')).
          check_files.should eq(OfflineAPI::Responses.file_not_found)
      end
    end
  end
  #...
####################################################
# /spec/models
####################################################
require 'spec_helper'

describe Decree do
  setup_and_teardown_tire_indexes(Decree)

  describe '.do_search' do
    it 'should return Decree which has given keyword' do
      decree = create(:decree_with_articles); refresh_indexes(Decree)
      Decree.search(:query => "lorem")[0].should eq(decree)
      decree.destroy; refresh_indexes(Decree)
    end

    it "shouldn't return Decree which hasnt given keyword" do
      decree = Decree.create!(:title => "a", :description => "b", :code => "c",
                             :url => "d")
      Decree.search(:query => "lorem").size.should eq(0)
    end
  end
end
####################################################
# /spec/models
####################################################
require 'spec_helper'
require "cancan/matchers"

describe User do

  its('factory'){ FactoryGirl.create(:user).should be_valid}
  %w'admin support pm client_agent'.each do |u|
    its("#{u} factory"){ FactoryGirl.create("#{u}_user".to_sym).should be_valid}
  end

  describe 'associations' do
    it { should have_and_belong_to_many(:clients) }
    it { should have_many(:report_distributions) }
    it { should have_many(:person_reports) }
    it { should have_many(:administration_subscriptions).dependent(:destroy) }
    it { should have_many(:administrations).through(:clients) }
  end

  describe 'validations' do
    it { should validate_presence_of :name }
    it { should validate_presence_of :email }
  end
  #...
####################################################
# /spec/workers
####################################################
require 'spec_helper'

describe TwitterPoster do

  context "web hook" do

    it 'should tweet given params', :vcr do
      news = create(:news)
      news_title = "Buongiorno"
      news_id = news.id
      url = 'http://www.sentenzeitalia.it' + "/#news/#{news_id}"
      TwitterWrapper.any_instance.should_receive(:tweet).with(news_title, url, news_id)
      subject.perform(news_title, url, news_id)
    end
  end

end
####################################################
