####################################################
# used for jQeury Datatables

class SurveyReportsDatatable
  include ActionView::Helpers::UrlHelper

  def initialize(params)
    @params = params
  end

  def as_json(options = {})
    {
      aaData: data,
      sEcho: @params[:sEcho].to_i,
      iTotalRecords: SurveyReport.where(survey_report_set_id: @params[:survey_report_set_id]).count,
      iTotalDisplayRecords: total_records
    }
  end

  private

  def data
    reports.map do |survey_report|
      [
        survey_report.id,
        survey_report.teacher.try(:full_name),
        survey_report.organization.try(:name),
        survey_report.status,
        link_to("Preview PDF", Rails.application.routes.url_helpers.survey_report_path(id: survey_report.id), 
                target: "_blank", class: "btn btn-default")
      ]
    end
  end

  def reports
    @all_reports ||= fetch_reports
    @reports = @all_reports.page(page).per_page(per_page)
  end

  def total_records
    @all_reports.count
  end

  def fetch_reports
    reports = SurveyReport.includes(:teacher).where(survey_report_set_id: @params[:survey_report_set_id]).
      order("#{sort_column} #{sort_direction}")
    search_params = {
      id: @params[:sSearch_0],
      teacher_name: @params[:sSearch_1],
      status: @params[:sSearch_2]
    }
    SurveyReport::FinderService.search_by(reports, search_params)
  end

  def page
    @params[:iDisplayStart].to_i / per_page + 1
  end

  def per_page
    @params[:iDisplayLength].to_i > 0 ? @params[:iDisplayLength].to_i : 10
  end

  def sort_column
    columns = ["survey_reports.id", nil, nil, "survey_reports.status"]
    columns[@params[:iSortCol_0].to_i]
  end

  def sort_direction
    @params[:sSortDir_0] == "desc" ? "desc" : "asc"
  end
end
