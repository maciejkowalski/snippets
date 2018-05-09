####################################################
# /lib
####################################################
module ApplicantOne
  class JobsCreator
    include Integration::JobsCreatorHelpers

    def initialize(user, company, department_id = nil)
      self.user, self.company, self.department_id = user, company, department_id
      self.query = QueryObjects::ATSJob::ApplicantOneQuery.new
    end

    def upsert(attrs)
      if attrs[:applicant_one_jobkey].present? && (job = query.get_job(company, user, attrs[:applicant_one_jobkey]))
        update(job, attrs)
      else
        create(attrs)
      end
    end

    private
    attr_accessor :user, :company, :department_id, :query

    def create(attrs)
      params = convert_jobkey(attrs)
      params = add_department_id(add_location_to_attrs(params), department_id)
  #...
#####################################################
module Integrations
  module Aweber
    class Oauth
      def request_token(callback_url)
        client.request_token(oauth_callback: callback_url)
      end

      def authorize(verification_code, oauth_token = "", secret = "")
        setup_token_from_params(oauth_token, secret)
        client.authorize_with_verifier(verification_code)
      end

      def authorize_with_access(token, secret)
        client.authorize_with_access(token, secret)
        client
      end

      def client
        @client ||= AWeber::OAuth.new(ENV['INTEG_AWEBER_KEY'], ENV['INTEG_AWEBER_SECRET'])
      end

      private

      def setup_token_from_params(oauth_token, secret)
        client.request_token = OAuth::RequestToken.from_hash(
          client.consumer,
          oauth_token: oauth_token,
          oauth_token_secret: secret,
        )
      end
    end
  end
end

####################################################
# ES indexer that uses threads - run with JRuby
class SentenceIndexer
  # this class is used to index ElasticSearch via Tire
  # run with rake task & JRuby
  def initialize(max_threads=4)
    @max_threads = max_threads
    @index_name = "#{Sentence.index_name}_#{Time.now.strftime('%Y%m%d%H%M%S')}"
    @alias_name = "#{Sentence.index_name}"
  end

  def get_current_index
    al = get_alias
    al.indices.first
  end

  def start
    puts "Using alias: #{@alias_name}"
    puts "Using index: #{@index_name}"
    puts "Waiting 5 seconds press <Ctrl-C> if you want to stop"
    sleep 5
    index = Tire::Index.new(@index_name)
    index.create(settings: Sentence.tire.settings, :mappings => Sentence.mapping_to_hash)
    start_index index
    complete
  end

  def get_alias
    find_or_create_alias(@alias_name)
  end

  def complete
    current = get_alias
    old_indices = current.indices.to_a
    current.indices.clear
    current.index @index_name
    current.save

    old_indices.each do |name|
      puts "Deleting: #{name}"
      Tire::Index.new(name).delete
    end
  end

  def start_index index
    threads = (1..@max_threads).map do |thread_num|
      Thread.new { thread_job(thread_num, index)}
    end
    threads.each { |t| t.join }
  end

  def thread_job thread_num, index, total = Sentence.published.count
    puts "Starting thread: #{thread_num}"
    n = thread_num
    while (arr = Sentence.published.page(n).per(1000).includes(:rules, :regulations).order(:id)) && !arr.blank? do
      puts "Thread#{thread_num}: Importing #{n * 1000}/#{total}"
      index.bulk_store(arr)
      n += @max_threads
    end
  end

  private

  def check_index name
    puts "Checking index"
    return false if name.blank?
    ts = Tire.search(name)
    ts.query{string('appalto')}
    ts.results.total_count > 15000
  end

  def find_or_create_alias str
    Tire::Alias.find(str) || Tire::Alias.new(name: str)
  end
end
####################################################
# base class for rendering mechanism of `events`
module RoyalEvents
  module Renderers
    class Base
      include AppContracts
      include Rails.application.routes.url_helpers
      include ActionView::Helpers::SanitizeHelper

      DATE_FORMAT = '%b %d, %Y'.freeze

      attr_reader :event
      delegate :strategy_data, to: :@event
      delegate :strategy_slug, to: :@event
      delegate :subscription, to: :@event
      delegate :user, to: :@event

      def self.group_slug
        to_s.split('::')[2..-1].join.underscore
      end

      def initialize(event)
        @event = event
      end

      Contract OneOf[RoyalEvents::Renderers::TEMPLATE_TYPES], OneOf[RoyalEvents::Renderers::FORMATS] => String
      def render(template_type = :email, format = :html)
        set_time_zone do
          render_template(template_type.to_s, format)
        end
      end

      def template_data
        raise NotImplementedError
      end

      def full_template_data
        event_created_at = @event.created_at.strftime(DATE_FORMAT)

        template_data.merge(
          event_created_at: event_created_at,
          event: @event,
        )
      end

      # it's used for group same events
      def group_slug
        self.class.group_slug
      end

      # template_type - email, website (differentiate between various templates)
      # sample input: 'email'
      # sample output: 'state_bill/email/actions'
      def filename(template_type)
        classpath = self.class.to_s.split('::')[2..-1].join('::')
        dir, file = classpath.underscore.split('/')
        path = File.join(dir, template_type, file)

        if filename_suffix.present?
          path = File.join(path, filename_suffix)
        end

        path
      end
      # [...]
####################################################
# ES query subclass
module Search
  module Topic
    module Item
      class Query < Base::Query
        def index_slug
          'topic_items'
        end

        def index_type
          'topic_item'
        end

        private

        def search_query
          bool(
            :must,
            [
              query_current_user_topic_items,
              query_text,
              query_record_slugs,
              query_topic_token,
            ]
          )
        end

        def query_current_user_topic_items
          term(
            'topic.owner_id',
            form.user_id
          )
        end

        def query_text
          simple_query_string(
            [
              'item_hash.title',
            ],
            form.text
          )
        end

        def query_record_slugs
          terms(
            'record_slug',
            form.record_slugs
          )
        end

        def query_topic_token
          term(
            'topic.token',
            form.topic_token
          )
        end

        def sort
          [
            order_by(:created_at, :desc)
          ]
        end
      end
    end
  end
end

