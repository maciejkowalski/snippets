####################################################
# app/workers (Sidekiq)
####################################################
class Reports::SurveyReportCreatorWorker
  include Sidekiq::Worker

  def perform(results_ids_for_person, survey_report_set_id, organization_id, organization_type, person_id)
    survey_report_set = SurveyReportSet.find(survey_report_set_id)
    report_type = survey_report_set.report_type
    rdo = build_rdo(report_type, results_ids_for_person, survey_report_set.survey_model_score_types)

    report_type.constantize.create!(
      rdo: rdo,
      survey_report_set_id: survey_report_set_id,
      organization_id: organization_id,
      organization_type: organization_type,
      person_id: person_id)
  end

  private

  def build_rdo(report_type, results_ids_for_person, survey_model_score_types)
    results_for_person = SurveyResult.where(id: results_ids_for_person)

    rdo_builder(report_type).build(results_for_person, survey_model_score_types)
  end
  #...
####################################################
# Sidekiq Pro batch usage
####################################################
class Publishment::PageVariantWorker
  include Sidekiq::Worker
  sidekiq_options retry: false

  def perform(page_variant_id, publish_params)
    @publish_params = publish_params.with_indifferent_access
    @page_variant = PageVariant.find(page_variant_id)
    @page_variant.update!(publishment_status: "waiting")

    depublish_page_variant() if publish_type_changed?
    @page_variant.custom_domain_cleanup if @publish_params[:custom_domain] != @page_variant.custom_domain

    schedule_pages_publishment_batch # START PUBLISHMENT

    @page_variant.update!(publishment_status: "in_progress")
  end

  private
  def schedule_pages_publishment_batch
    batch = Sidekiq::Batch.new
    success_hash = { page_variant_id: @page_variant.id, publish_params: @publish_params }
    batch.on(:success, Publishment::Callbacks, success_hash)
    batch.on(:complete, Publishment::Callbacks, :page_variant_id => @page_variant.id)
    batch.jobs do
      @page_variant.active_main_pages.each do |main_page|
        Publishment::PageWorker.perform_async(main_page[:id], @publish_params)
      end
    end

    puts "Just started batch #{batch.bid}"
  end

####################################################
# Sidekiq PRO callbacks (Batches)
####################################################
class Publishment::Callbacks
  def on_complete(status, options)
    if status.failures != 0
      Publishment::RollbackWorker.perform_async(options['page_variant_id'])
      page_variant = PageVariant.find(options['page_variant_id'])
      page_variant.update!(publishment_status: "failed")
    end
  end

  def on_success(status, options)
    publish_params = options['publish_params'].with_indifferent_access

    if publish_params[:type] == 'custom-domain'
      Publishment::AddDomainWorker.perform_async(options['page_variant_id'], publish_params[:custom_domain])
    end
  end
end
