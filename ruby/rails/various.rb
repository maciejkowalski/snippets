####################################################
## app/admin
####################################################
ActiveAdmin.register OfflineUser do
  menu parent: 'Scaricabile', if: proc { current_admin_user.can_edit? 'OfflineUser' }

  collection_action :import_from_csv, method: :put do
    OfflineUserCSVImporter.new.import_from_uploaded_file(params[:csv_file])
    redirect_to admin_offline_users_import_path, notice: "Users imported from CSV file"
  end

  decorate_with OfflineUserDecorator

  index do
    column :id
    column t("username"), :username
    column t("password"), :password
    column t("email"), :email
    column t(:full_name), :full_name
    column t(:token), :token
    column t(:expiring_at), :subscription_expiring_at
    default_actions
  end

  show do |user|
    render :partial => 'show', locals: {user: user.decorate}
  end
  #...
####################################################
module ActiveAdmin::BatchActions
  # monkey patch to delete toggle select checkbox
  class ResourceSelectionTogglePanel < ActiveAdmin::Component
    def build
    end
  end
end

ActiveAdmin.register SystemConfiguration do
  actions :index, :edit, :update
  menu :if => proc { current_admin_user.can_edit? 'SystemConfiguration' }

  index :as => :block do |sc|
    div :for => sc do
      div do
        label "News from: "
        span sc.news_from
      end
  #...
####################################################

####################################################
# app/decorators (Draper)
####################################################
class OfflineUserDecorator < Draper::Decorator
  delegate_all

  def full_name
    [source.first_name, source.last_name].compact.join(' ')
  end

  def address
    "#{source.address} - #{source.postal_code}, #{source.city}"
  end

  def concurrent_sessions
    source.unlimited_sessions? ? I18n.t(:unlimited) : source.contemporary_sessions
  end
end

####################################################
# app/policies (pundit)
####################################################
class TopicItemPolicy < ApplicationPolicy
  class Scope < Scope
    def resolve
      TopicItem.joins(:topic).
        where(topics: { owner_id: user.id })
    end
  end

  def show?
    current_user_topic_item?
  end

  def destroy?
    current_user_topic_item?
  end

  private

  def current_user_topic_item?
    record.topic.owner_id == user.id
  end
end

####################################################
# app/validators
####################################################
class RequiredInputsValidator < ActiveModel::EachValidator
  include ClassyHashValidable
  attr_reader :record, :attribute, :value, :errors

  def validate_each(record, attribute, value)
    @record = record
    @attribute = attribute
    @value = value
    @errors = record.errors # for ClassyHashValidable

    uniqueness_of_subscription
    required_inputs_presence_and_type
    uniqueness_of_keyword
  end

  private

  def uniqueness_of_subscription
    duplicated_subscription = find_duplicated_subscriptions

    if duplicated_subscription
      if record.persisted? && duplicated_subscription.id == record.id
        return # duplicate is equal to record, allow update
      end

      errors.add(
        "subscription.#{record.subscribable_slug}",
        'Duplicated subscription'
      )
    end
  end
  # [...]
