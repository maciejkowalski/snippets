####################################################
# app/controllers
####################################################
class ApplicationController < ActionController::Base
  protect_from_forgery
  before_filter :authenticate_user!

  rescue_from CanCan::AccessDenied do |exception|
    redirect_to root_path, alert: exception.message
  end

  private

  def after_sign_out_path_for(resource)
    stored_location_for(:user) || new_user_session_path
  end

  def render_404
    raise ActionController::RoutingError.new('Not Found')
  end
  # ...
####################################################
class AdministrationResponseExportsController < ApplicationController
  before_filter :load_administration, except: [:download, :destroy]
  load_and_authorize_resource except: [:index]

  def index
    authorize! :show, @administration
    @administration_response_exports = @administration.administration_response_exports.order(:id).reverse_order
    add_administration_base_breadcrumbs(@administration, "Response Exports")
  end
  #...
####################################################
class Employer::RequestReferralsController < ApplicationController
  respond_to :json
  before_filter :allow_employer_and_recruiter

  def index
    job = current_company.jobs.find params[:job_id]
    matches = Company::ContactMatchesService.new(current_company).get_matches(job)

    respond_with RequestReferrals::EmployerFilterService.new(current_company, job).filter(params, matches)
  end

  def create
    if params[:employee_ids].present? && RequestReferrals::SenderService.send(params, current_company, current_user)
      render json: {}, :status => 200
    else
      render json: {}, :status => :unprocessable_entity
    end
  end
  #...
####################################################
class Api::AnalyticsController < ApplicationController
  respond_to :json

  def index
    page = Page.where(page_variant_id: params[:page_variant_id]).first
    authorize! :update, page

    page_analytics_data = Analytics::PageAnalyticsService.new.filter(permitted_params)
    overview_chart = Analytics::OverviewChartService.new.filter(permitted_params)

    hash = {}
    hash[:page_analytics] = page_analytics_data.as_api_response(:standard)
    hash[:conversion_goals] = ConversionGoal.filter(params[:page_variant_id]).as_api_response(:standard)
    hash[:overview_chart] = overview_chart.as_api_response(:standard)

    render json: hash
  end
  # [...]
####################################################
module ApiWeb
  module Rolodex
    class ContactsController < ApiWeb::BaseController
      include SearchFormConcern
      after_action :verify_authorized, except: [:index]

      def index
        strategy = Search.new(
          'rolodex_custom_contact',
          contacts_params
        )
        rolodex_contacts = strategy.search

        render json: {
          data: ActiveModel::ArraySerializer.new(
            rolodex_contacts,
            each_serializer: ::Rolodex::Search::CustomContactSerializer,
          ),
          pagination: pagination_attributes(rolodex_contacts),
        }
      end

      def create
        creator = ::Rolodex::ContactCreator.new(current_user, contact_params)
        contact = creator.rolodex_contact
        authorize contact

        if contact.save
          render(
            json: ::Rolodex::ContactSerializer.new(
              contact
            ),
            status: :created
          )
        else
          render(
            json: contact.errors,
            status: :unprocessable_entity
          )
        end
      end
      # [...]

####################################################
# controller concern - conversions
####################################################
module ConversionTracking
  extend ActiveSupport::Concern

  private
  def conversion_exists?(conversion_goal_id, page_path)
    (conversion_goals_ids = get_conversion_goals_ids_from_cookie(page_path)) &&
        conversion_goals_ids.has_key?(conversion_goal_id)
  end

  def upsert_conversions(conversion_goal_id, page_path)
    raise "Empty page path" if page_path.blank?

    conversion_goals_ids_hash = get_conversion_goals_ids_from_cookie(page_path) || {}
    conversion_goals_ids_hash[conversion_goal_id] = true

    source_token = get_source_page_token(page_path)

    cookies.signed[cookie_key(source_token)] = {
        value: conversion_goals_ids_hash.to_json,
        expires: 6.months.from_now
    }

    _params = conversion_params
    _params[:uuid] = SecureRandom.uuid
    _params[:unique_page_visit_id] = @unique_page_visit.id
    _params[:page_id] = @unique_page_visit.page_id
    _params[:basepage_id] = @unique_page_visit.basepage_id
    @conversion = Conversion.create!(_params)
  end

  def get_conversion_goals_ids_from_cookie(page_path)
    source_token = get_source_page_token(page_path)
    if cookies.signed[cookie_key(source_token)]
      ActiveSupport::JSON.decode(cookies.signed[cookie_key(source_token)])
    else
      nil
    end
  end
  # [...]
