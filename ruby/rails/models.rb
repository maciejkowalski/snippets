####################################################
# app/models
####################################################
class SocialMediaPost < ActiveRecord::Base
  belongs_to :postable, polymorphic: true
  belongs_to :people_list

  enum social_media_type: [:facebook, :twitter] # PostgreSQL + RoR => enum support
####################################################
class ReportV2::RDOConstructBuilder
  include ReportV2::ComparativeHelpers

  def build(survey_model_element, score_set, comparative_score_sets)
    construct = ReportV2::Rdo::Construct.new
    construct.score = score_set.construct_scores[survey_model_element.id.to_s]
    # { 'D' => {"2"=>"0.932", "3"=>"0.952"..},  'S' => {"2"=>"0.932", "3"=>"0.952"..}, ..}
    construct.comparatives = build_hash(comparative_score_sets, survey_model_element.id)
    construct.items = build_rdo_survey_schema_items(survey_model_element, score_set)
    construct.construct = survey_model_element.name

    construct
  end
  #...
####################################################
class SevenCReportV1::RDOSummary
  include Virtus.model

  attribute :cohorts_map, Hash[String => SevenCReportV1::RDOSummaryItem]
end
####################################################
class HistoryTracker
  include Mongoid::History::Tracker

  def as_json(options = {})
    super(options).tap do |json|
      json[:created_at] = self.created_at.to_s
      json[:model_name] = self.association_chain.first["name"]

      json[:username] = "Activecell"
      json[:username] = User.find(self.modifier_id).name if self.modifier_id
    end
  end
end
####################################################
class SurveyReport < ActiveRecord::Base
  include Extensions::Fileable

  belongs_to :survey_report_set, counter_cache: :reports_count
  belongs_to :teacher, class_name: "Person", foreign_key: "person_id"
  belongs_to :organization, polymorphic: true

  attr_accessible :type, :survey_report_set, :survey_report_set_id, :rdo, :report_password, :status, :person_id,
    :organization, :organization_id, :organization_type, :teacher

  attr_encrypted :report_password, key: Figaro.env.survey_report_password_key, :encryptor => AttrEncryptedPgcrypto::Encryptor, :encode => false

  delegate :anonymize?, :encrypt?, :client_name, :season, :year, :comparative_types, :has_client_logo?,
    :client_logo_base64, :minimum_responses_to_generate_report,
    to: :survey_report_set
  #...
####################################################
class GotowebinarAccount < Integration # STI
  def account_key
    settings['organizer_key']
  end

  def provider
    settings['provider']
  end

  def service
    Integrations::GoToWebinar::Service.new(self)
  end

  # @param [Hash] data user's data as it comes from the browser
  # @return [Hash] with user's data put in appropriate fields
  def default_mappings(data)
    {
      'firstName' => data['first_name'],
      'lastName' => data['last_name'],
      'email' => data['email']
    }.compact
  end

  def target
    { organizer_key: account_key }
  end

  private

  def update_settings
    GotowebinarGetWebinarWorker.perform_async(id)
  end
end
####################################################

####################################################
# concern for models
####################################################
module Api::BelongsCompany
  extend ActiveSupport::Concern
  include Mongoid::Timestamps
  include Mongoid::Paranoia
  include Mongoid::History::Trackable

  included do
    belongs_to :company

    # audit trail
    track_history on: :all,
      modifier_field: :modifier, modifier_field_inverse_of: nil,
      track_create: true, track_update: true, track_destroy: true
  end

  # Default json presentation without company_id
  # and with updated_at, deleted_at fields
  def as_json(options = {})
    options[:except] = (options[:except] || []) + [:company_id]
    options[:only] = options[:only] + [:updated_at, :deleted_at] if options[:only]
    super(options)
  end
  #...
####################################################
module Intercomable
  # Classes including this concern are expected to define intercom_email
  def intercom_email
    raise "#{self.class} does not define intercom_email"
  end

  def intercom_event event_name, args={}
    return if Rails.env.test?
    Intercom::Event.create args.merge({
      event_name: event_name,
      created_at: Time.current.to_i,
      email: intercom_email
    })
  end

  def intercom_user_custom_attributes args
    user = Intercom::User.find(email: intercom_email)
    args.each {|k, v| user.custom_attributes[k] = v }
    user.save
  end
end
