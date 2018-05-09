####################################################
require 'spec_helper'

describe ClientLogosController do
  with_user :admin_user

  let(:client) { FactoryGirl.create(:client) }
  let(:client_logo) { FactoryGirl.create(:client_logo, client: client) }

  def valid_attributes
    {
      client_id: client.id,
      file: fixture_file_upload("images/1x1.gif")
    }
  end

  def valid_session
    {"warden.user.user.key" => session["warden.user.user.key"]}
  end

  describe "/index" do
    it "assigns @client" do
      get :index, {client_id: client.id}, valid_session
      expect(response).to be_ok
      expect(assigns(:client)).to eq(client)
    end

    it "assigns @client_logos with all the client logos for the specified client" do
      logo_1 = FactoryGirl.create(:client_logo, client: client)
      logo_2 = FactoryGirl.create(:client_logo, client: client)
      get :index, {client_id: client.id}, valid_session
      expect(response).to be_ok
      expect(assigns(:client_logos).size).to eq(2)
      expect(assigns(:client_logos)).to include(logo_1, logo_2)
    end

    it "returns 404 if a client is not found" do
      get :index, {client_id: 99999}, valid_session
      expect(response).to be_not_found
    end
  #...

####################################################
require 'spec_helper'

describe SurveyReportsController do
  with_user :admin_user

  let(:administration) { FactoryGirl.create(:administration) }
  let(:survey_report_set) { FactoryGirl.create(:survey_report_set, administration: administration) }
  let(:survey_report) { FactoryGirl.create(:seven_c_report_v1,
                                           survey_report_set: survey_report_set,
                                           teacher: create(:person)) }

  describe 'GET index' do
    render_views

    it 'uses the SurveyReportsDatatable' do
      request.env["HTTP_ACCEPT"] = 'application/json'
      expect(SurveyReportsDatatable).to receive(:new)
      get :index, {survey_report_set_id: survey_report_set.id}, valid_session
    end

    it 'loads SurveyReportSet' do
      get :index, {survey_report_set_id: survey_report_set.id}, valid_session
      expect(assigns(:survey_report_set)).to eq(survey_report_set)
    end
  #...
####################################################
require 'rails_helper'

describe Api::InvoicesController do
  describe '#show' do
    let(:user) { create :user, :with_subscription }
    let(:customer_id) { user.subscription.customer_id }
    let(:invoice_id) { '101' }

    before do
      StripeMock.start; create_stripe_plans
      login_as(user)
      allow(Stripe::Invoice).to receive(:all)
        .with(customer: customer_id)
        .and_return(
          Hashie::Mash.new(data: [{ id: invoice_id }])
        )
    end
    after { StripeMock.stop }

    it 'schedules email' do
      get :show, id: invoice_id
      expect(response.status).to eq 204
      expect(EmailInvoiceWorker.jobs).not_to be_empty
      expect(EmailInvoiceWorker.jobs.first['args']).to eq [user.id, invoice_id]
    end
  # [...]
####################################################
# is_expected -> one-liner expect(subject)
####################################################
require 'rails_helper'

describe Api::FavoriteWidgetsController do
  before { login_as user }
  let(:page) { create :page }
  let(:widget) { create :widget, project: page.project, page: page }
  subject { response.status }

  context 'own' do
    let(:user) { create :user, account: widget.project.account }
    let!(:favorite_widget) { create(:favorite_widget, account: widget.project.account, widget: widget) }

    it 'updates' do
      put :update, id: widget.id
      is_expected.to eq 200
    end

    it 'deletes' do
      delete :destroy, id: widget.id
      is_expected.to eq 204
    end
  end
  # [...]
####################################################
# some metaprogramming
####################################################
require 'rails_helper'

describe ProjectsController do
  let(:id) { 111 }
  let(:project_id) { project.id }
  let(:project) { create :project, account: account }
  let(:account) { user.account }
  let(:user) { create :user, :with_subscription }
  let(:another_user) { create :user, :with_subscription }

  before { StripeMock.start; create_stripe_plans }
  after { StripeMock.stop }

  %w[active_campaign mailchimp aweber hubspot salesforce infusionsoft gotowebinar].each do |integration_name|
    klass = (integration_name.camelcase + 'Account').constantize
    integration = integration_name.tr '_', ''
    context integration do
      before { klass.create! project_id: project_id, id: id }
      describe "#disconnect_from_#{integration}" do
        it 'removes integration' do
          login_as user

          delete "disconnect_from_#{integration}".to_sym,
            project_id: project_id,
            account_id: id
          expect(klass.all).to be_empty
        end
  # [...]

####################################################
# /spec/features
####################################################
require 'spec_helper'

describe 'routes for home path for logged users' do

  %w(admin_user pm_user support_user client_agent_user).each do |user_role|

    context "when #{user_role} logged in" do
      it 'routes to Administration Subscribed index page' do
        FactoryGirl.create_list(:administration, 2)
        Administration.stub(:subscribed_by) { Administration.all }
        login_with(create(user_role, password: 'please'), password: 'please')

        expect(page.find(".section-title").text).to eq("Subscribed Administrations")
      end
    end
  end

  context "when principal logged in" do
    it 'routes to home index page' do
      principal = create(:principal_user, password: 'please')
      login_with(principal, password: 'please')

      expect(page.find(".section-title").text).to eq("Rosters")
    end
  end
end
####################################################
require 'spec_helper'

feature 'on rosters page' do
  let!(:administration) { create(:administration) }
  let!(:roster) { create(:roster, state: :processed, administration: administration) }
  let!(:user) { create(:admin_user) }

  background 'login' do
    login_with(user, password: 'please')
    visit administration_rosters_path(administration)
  end

  context 'when create survey order button is clicked' do
    before do
      click_link 'Create Survey Order'
    end

    scenario 'survey order is created and survey order list is displayed' do
      expect(SurveyOrder.count).to eq(1)
      expect(current_path).to eq(administration_survey_orders_path(administration))

      within 'ul.survey-order-tabs' do
        page.should have_css('li.survey-order', count: 1)

        within 'li.survey-order:first' do
          within '.resource-id' do
            page.should have_content("#{SurveyOrder.first!.id}")
          end

          within 'div.order-status' do
            page.should have_content('Enqueued')
          end
        end
      end
    end
  #...
####################################################
# /spec/lib
####################################################
# encoding: utf-8
require 'spec_helper'

describe OfflineUserCSVImporter do
  let(:filename){File.join(File.dirname(__FILE__), '..', 'fixtures', 'offline_users.csv')}
  let(:subject){OfflineUserCSVImporter.new(filename)}

  describe '.import' do
    context 'given valid csv file' do
      it 'should import file and increate OfflineUser count' do
        OfflineUser.should_receive(:delete_all).once
        expect{
          subject.import
        }.to change{OfflineUser.count}.from(0).to(2)
      end
    end
  end
end

####################################################
require 'spec_helper'

describe ApplicantOne::XMLImporter, :my_company do

  let!(:company) { FactoryGirl.create :company }
  let!(:user) { FactoryGirl.create :employer, company: company }
  let!(:category) { FactoryGirl.create :category, name: "Other" }
  let!(:credential) { FactoryGirl.create :applicant_one_credential, company: company }
  subject { described_class.new(user, company) }

  describe '#sync_jobs' do
    context 'when departments are disabled' do
      it 'creates and updates jobs', :vcr do
        expect { subject.sync_jobs }.to change(company.jobs, :count).by(45)
      end
    end

    context 'when departments are enabled' do
      before { company.update_attributes(departments_enabled: true) }

      it 'creates and updates jobs', :vcr do
        expect { subject.sync_jobs }.to change(company.jobs, :count).by(45)
      end
    end
  end

  let!(:url) { "https://www.applicantone.com/jobboards/employeereferralscom" }
  let!(:file_content) do
    File.read(File.join(Rails.root, "spec", "fixtures", "employeereferralscom.xml"))
  end

  describe '#get_file_content private' do
    it 'returns fetched file content', :vcr do
      expect(subject.send(:get_file_content, url)).to eq(file_content)
    end
  end
  #...
##################################################
require 'importer'

describe Importer do

  class FakeStrategy
    def initialize(context)
    end
    def import
    end
  end
  class FakeUser; end
  class FakeCompany; end

  let(:file) { open(File.join(File.dirname(__FILE__), '..', 'fixtures', 'jobs.csv')) }
  subject do
    Importer.new(FakeStrategy, file: file, user: FakeUser.new, company: FakeCompany.new)
  end

  it 'assigns instance variables' do
    expect(subject.instance_variable_get(:@file)).to_not be_nil
    expect(subject.instance_variable_get(:@user)).to be_a(FakeUser)
    expect(subject.instance_variable_get(:@company)).to be_a(FakeCompany)
  end

  describe '#import' do
    it 'calls @importer #import' do
      subject.importer.should_receive(:import)
      subject.import
    end
  end

  describe '#valid_mappings?' do
    it 'calls @importer #import' do
      subject.importer.should_receive(:valid_mappings?)
      subject.valid_mappings?
    end

  end
end
####################################################
# /spec/models
####################################################
require 'spec_helper'

describe ReportV2::Organization::RDOBuilder do

  describe '.create_children' do
    let(:survey_model_id_to_score_type_id) do
      described_class.new.
        send(:survey_model_id_to_score_type_id, OrganizationReportV2.default_settings[:survey_model_score_types])
    end
    let(:survey_results) do
      [
        FactoryGirl.build(:survey_result, teacher: person_1),
        FactoryGirl.build(:survey_result, teacher: person_2)
      ]
    end
    let!(:survey_result_school) do
      FactoryGirl.build(:survey_result, organization_type: 'K12School', person_id: nil)
    end
    let!(:person_1){FactoryGirl.build :person}
    let!(:person_2){FactoryGirl.build :person}

    before do
      expect(subject).to receive(:teacher_client_survey_results_by_schoolid).and_return(survey_results)
    end

    it 'generates rdo children nodes for each found teacher client survey result' do
      expect(ReportV2::Rdo::ChildrenNode).to receive(:new).exactly(2).times
      subject.create_children(survey_result_school, survey_model_id_to_score_type_id)
    end

    it 'returns an array of ReportV2::Rdo::ChildrenNodes' do
      result = subject.create_children(survey_result_school, survey_model_id_to_score_type_id)
      expect(result).to be_a(Array)
      result.each{|r| expect(r).to be_a(ReportV2::Rdo::ChildrenNode)}
    end
  end
  #...
####################################################
require "spec_helper"

describe ReportV2::Comparatives do
  let!(:rdo) do
    {
      "S" => 1.1,
      "D" => 2.2
    }
  end

  subject { described_class.new(rdo) }

  it "is a kind of OpenStruct" do
    expect(subject).to be_an(OpenStruct)
  end

  describe "#scores_by_labels" do
    it "returns scores by the labels passed" do
      expect(subject.scores_by_labels(["S", "D"])).to eq [1.1, 2.2]
    end

    it "returns nil for the lables that are not recognized" do
      expect(subject.scores_by_labels(["E", "S"])).to eq [nil, 1.1]
    end
  end
  #...
####################################################
require 'spec_helper'

describe HistoryTracker do

  describe '#as_json' do

    let(:history_tracker) { HistoryTracker.last }
    before { create(:cust_acq_forecast, value: 123) }
    subject { history_tracker.as_json }

    it 'includes model_name' do
      expect(subject[:model_name]).to eq(history_tracker.association_chain.first["name"])
    end

    it 'includes event type' do
      expect(subject["action"]).to eq(history_tracker.action)
    end

    context 'when modifier is present' do
      let!(:user) { create(:user) }
      before { history_tracker.update_attributes(modifier: user) }

      it 'prints modifier username' do
        expect(subject[:username]).to eq(user.name)
      end
    end

    context 'when modifier is blank' do
      it 'returns Activecell' do
        expect(subject[:username]).to eq("Activecell")
      end
    end
  end
end
#################################################################
# spec/workers
#################################################################
require 'rails_helper'

RSpec.describe Publishment::Callbacks do
  let(:page) { create(:page) }
  let(:page_variant) { page.page_variant }
  let(:publish_params) { { type: "immediate", token: "a1s2d3" } }
  let(:success_hash) {{ 'page_variant_id' => page_variant.id, 'publish_params' => publish_params }}

  SidekiqStatusStub = Struct.new(:failures)

  describe '#on_complete' do
    context 'when at least one job failed' do
      it 'schedules RollbackWorker and marks page variant publishment status as \'failed\'' do
        expect(Publishment::RollbackWorker).to receive(:perform_async).with(page_variant.id)
        subject.on_complete(SidekiqStatusStub.new(1), success_hash)
        expect(page_variant.reload.publishment_status).to eq('failed')
      end
    end
  # [...]
