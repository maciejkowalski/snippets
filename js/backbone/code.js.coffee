####################################################
# /app/assets/javascripts
####################################################
Backbone.View::handlebarsTemplate = (templateName) ->
  Handlebars.compile $(templateName).html()

# More info at
# http://lostechies.com/derickbailey/2011/09/15/zombies-run-managing-page-transitions-in-backbone-apps/
Backbone.AppView = (selector) ->
  @selector = selector

_.extend Backbone.AppView::,
  getSelector: ->
    @selector

  show: (view) ->
    @currentView.close() if @currentView
    @currentView = view
    @currentView.render()
    $(@getSelector()).html @currentView.el

  clear: ->
    @currentView.close() if @currentView
    $(@getSelector()).html('')

  append: (view) ->
    @appendedView.close() if @appendedView
    @appendedView = view
    @appendedView.render()
    $(@getSelector()).append @appendedView.el

Backbone.View::close = ->
  @remove()
  @unbind()
  @onClose() if @onClose
####################################################  
class SI.Collections.SearchParametersCollection extends Backbone.Collection
  model: SI.Models.SearchParameter

  serialize: =>
    params = _(@where({enabled: true})).map (model) => 
      model.serialize()
    JSON.stringify(params)

  # Use this method when you want to be sure that there is only one param of given type
  # in other cases use default add
  replace: (what)=>
    non_empty = (what.isEmpty? && !what.isEmpty()) || (what.query? && what.query.length > 0)
    @remove(@where({type: what.type}), {silent: non_empty})
    @add(what) if non_empty

  clearAuthorities: (options) =>
    @remove(@where({type: 'authority'}), options)

  #...
####################################################    
class SI.Models.User extends Backbone.Model
  urlRoot: SI.urlFor("users/")

  initialize: ->
  	@favourites = new SI.Collections.Favourites(@get('favourites'))
  	@favourites.url = @urlRoot + @.getId() + '/favourites'

  getId: =>
    @get('id')
####################################################
class SI.Routers.Unauthorized extends Backbone.Router

  routes:
    'unauthorized': 'unauthorized'
    'please-login': 'pleaseLogin'

  initialize: =>
    @contentView = new Backbone.AppView(".js-content")
    @searchView = new Backbone.AppView(".js-searchbox")
    @sidebarView = new Backbone.AppView(".js-sidebar")

  unauthorized: =>
    @contentView.show(new SI.Views.UnauthorizedPopup(user: true))

  pleaseLogin: =>
    @contentView.show(new SI.Views.UnauthorizedPopup(user: false))
####################################################
# Modified Backbone.View.
# This methods are repeated over and over again so I thought it will be good
# to move them into separate class.
#
# When you want to use this class you must set variable:
#   @viewName - name of show View which will be created eg. "NewsShow"
class SI.ListView extends Backbone.View

  render: =>
    $(this.$el).html(@template)
    @addAll()
    this

  addAll: =>
    @addOne(model) for model in @collection.models

  addOne: (model) =>
    view = new window['SI']['Views'][@viewName]({model: model})
    view.render()
    $(this.$el).append(view.el)
    model.bind("remove", view.close)

  onClose: =>
    model.clear() for model in @collection.models
    @collection.reset()
	Model = require('lib/model')
####################################################
module.exports = class HistoryTracker extends Model

  toJSON: (options) =>
    attributes = _.clone(@attributes)
    detailsAttrs = {}
    $.each(attributes.modified, (key, value) =>
      unless key.match(/_id/) || key == 'values'
        detailsAttrs[key] = value
    )
    attributes.details = @details(detailsAttrs)
    attributes

  details: (hash) =>
    string = ""
    i = 0
    $.each(hash, (key, value) =>
      if i < 5
        string += "#{key}: #{value}<br />"
        i += 1
    )
    string
####################################################
View                = require('lib/view')
HistoryTrackers     = require('collections/history_trackers')

module.exports = class AuditTrail extends View
  template: HandlebarsTemplates["settings/audit_trail"]
  className: 'table-container'
  events:
    'click .prev-page': 'prevPage'
    'click .next-page': 'nextPage'

  initialize: ->
    @collection = new HistoryTrackers()
    @collection.fetch(reset: true)

    @columns = [
      id: "model_name"
      label: "Model"
      classes: 'row-heading'
    ,
      id: "action"
      label: "Event type"
    ,
      id: "username"
      label: "User"
    ,
      id: "created_at"
      label: "Date"
      format: (d) -> moment(d.created_at).format('YYYY-MM-DD')
    ,
      id: "details"
      label: "Details"
      classes: 'text-left'
    ]
    @listenTo @collection, 'reset', @render

  prevPage: =>
    @collection.prevPage()

  nextPage: =>
    @collection.nextPage()

  render: ->
    $(@el).html @template(
      currentPage: @collection.currentPage
      numPages: @collection.numPages
    )
    new TableStakes().el("#audit-trail")
      .columns(@columns)
      .data(@collection.toJSON())
      .render()

####################################################
class SI.Views.RegulationsForm extends Backbone.View
  events:
    'change select': 'paramsUpdated'
    'click #reset_regulations': 'resetRegulations'

  initialize: =>
    Backbone.Dispatcher.on('facets:reload', @render)
    @template = this.handlebarsTemplate('#regulations_form_hb')
    SI.CurrentSearchParams.on('reset', @resetSelects, this)
    SI.CurrentSearchParams.on('remove', @removeParam, this)
    SI.CurrentSearchParams.on('deserialized', @setupProperSelects, this)

  resetRegulations: (event) =>
    event.preventDefault() if event?
    SI.CurrentSearchParams.resetRegulations()

  # Used in render when we deserialize parameters
  setupProperSelects: =>
    @setupProperSelects = true

  # setup HTML select option from RegulationSearchParameter
  setupSelectedOptions: =>
    @setupProperSelects = false
    if SI.CurrentSearchParams.isParameterPresent('regulation')
      query = SI.CurrentSearchParams.getParameterQuery('regulation')
      $.each query, (key, value) =>
        switch key
          when 'name' then @chooseOptionFromSelect('#regulation-name', value)
          when 'norm_number' then @chooseOptionFromSelect('#regulation-number', value)
          when 'year' then @chooseOptionFromSelect('#regulation-year', value)
          when 'article' then @chooseOptionFromSelect('#regulation-article', value)
		  
####################################################
class JobLark.Concerns.Views.DepartmentsSelect

  @renderDepartments: (context, options = {}) ->
    if options?.selector? && options.departments?
      departments = options.departments
      selector = options.selector
      context.$(selector).html $('<option>')
      _.each departments.toJSON(), (model) ->
        context.$(selector).append $('<option>', {value: model.id}).text(model.name)
      context.$(selector).parent().show()
      context.$(selector).val(options.selected) if options.selected?
    else
      console.error 'Please pass departments collection and selector in options.'

  @updateTable: (value, options = {}) ->
    if options.departments?
      departments = options.departments
      model = departments.get(value)
      if model
        JobLark.navigateToQuery(department_id: model.id)
    else
      console.error 'Please pass departments collection in options.'

####################################################
class JobLark.Concerns.Views.JobUpdate

  @calculateReward: (context, val, options) ->
    reward = parseFloat(val.replace(/\$/, '').replace(/,/, ''))
    commission = reward * context.model.get('commission_rate')
    reward = 0 if isNaN(reward)
    commission = 0 if isNaN(commission)
    if options.update_view
      context.$(options.commission_field_id).html commission
      context.$(options.commission_field_id).formatCurrency
        colorize: true
        roundToDecimalPlace: JobLark.rewardPrecision(commission)
      context.$(options.total_reward_field_id).html reward + commission
      context.$(options.total_reward_field_id).formatCurrency
        colorize: true
        roundToDecimalPlace: JobLark.rewardPrecision(reward + commission)
    context.model.set(reward_amount: reward + commission)

    # Format Currency
    if @$('input#employee_reward').val().substr(1)*1 is 0
      @$('input#employee_reward').val('')
    @$('input#employee_reward').blur =>
    @$('#employee_reward').formatCurrency
      colorize: true
      roundToDecimalPlace: JobLark.rewardPrecision(val)
    reward

  @errorsSummary: (errors, message = null) ->
    summary = "Cannot update job because of following errors: \n\n"
    if message?
      summary += message
    else
      _.each(errors, (errors, field) =>
        summary += "#{field} - #{errors.join(', ')} \n\n"
      )

    summary

  @setSuccessNotification: (context) ->
    JobLark.notificator.success I18n.t('templates.employer.job_mass_edit.success_notification')
    element = "#mass-edit-job-#{context.model.id}"
    $(element).attr('style', 'border-left: 5px green solid;')
    setTimeout =>
       $(element).attr('style', 'border-left: 0px;')
    , 1500

  @setErrorNotification: (context, errors, message = null) ->
    errors_summary = JobLark.Concerns.Views.JobUpdate.errorsSummary(errors, message)
    JobLark.notificator.error errors_summary
    element = "#mass-edit-job-#{context.model.id}"
    $(element).attr('style', 'border-left: 5px red solid;')

  @getDepartmentName: (departments, id) ->
    department = _.find(departments, (d) =>
      id == d.id
    )
    department.name
#
