############################################################################
# wrapper 'class' for model, allows to 'extend' and 'include' (Ruby behaviour) functions from coffee classes
############################################################################
@SocialPro.module 'Entities', (Entities, App, Backbone, Marionette, $, _) ->

  moduleKeywords = ['extended', 'included']

  class Entities.Model extends Backbone.DeepModel

    getId: -> # MongoDB id getter
      @get('_id').$oid

    @extend: (obj) ->
      for key, value of obj when key not in moduleKeywords
        @[key] = value # Assign properties to the instance

      obj.extended?.apply(@)
      this

    @include: (obj) ->
      for key, value of obj when key not in moduleKeywords
        @::[key] = value # Assign properties to the prototype

      obj.included?.apply(@)
      this
###########################################################################
# comparator
@SocialPro.module 'Entities', (Entities, SocialPro, Backbone, Marionette, $, _) ->
  # [...]
  class Entities.Leads extends Entities.Collection
    model: Entities.Lead
    url: -> '/api/leads'

    comparators:
      desc: (lead) -> return -lead.get("timestamp")
      asc: (lead) -> return lead.get("timestamp")

    setComparator: (key) ->
      @comparator = @comparators[key]
      this

    dateFilter: (startDate, endDate) ->
      filtered = @filter (lead) ->
        lead.get('created_at') >= startDate and lead.get('created_at') <= endDate
      return new SocialPro.Entities.Leads(filtered)
############################################################################
# Marionette Behaviour -> mixin
############################################################################
CopyableWidget = Marionette.Behavior.extend(
  ui:
    copyToDesktop   :'.copy-widget-to-desktop'
    copyToTablet    :'.copy-widget-to-tablet'
    copyToMobile    :'.copy-widget-to-mobile'

  events:
    "change @ui.copyToDesktop"    : (e) -> @copyWidgetTo($(e.target), 'desktop')
    "change @ui.copyToTablet"     : (e) -> @copyWidgetTo($(e.target), 'tablet')
    "change @ui.copyToMobile"     : (e) -> @copyWidgetTo($(e.target), 'mobile')

  builderChannel: Backbone.Radio.channel('builder')

  initialize: ->
    @variant = @builderChannel.request 'get:variant'
    @widget = @view.options.model
    @groupId = @widget.get('group_id')
    @pageId = @widget.get('page_id')
    @device = @widget.get('device_type')

  onRender: -> @loadLinkablePages()

  bindCKEditorCopyTo: ($ckeToolbar) ->
    $ckeToolbar.find(@ui.copyToDesktop).on 'change', (e) => @copyWidgetTo($(e.target), 'desktop')
    $ckeToolbar.find(@ui.copyToTablet).on 'change', (e) => @copyWidgetTo($(e.target), 'tablet')
    $ckeToolbar.find(@ui.copyToMobile).on 'change', (e) => @copyWidgetTo($(e.target), 'mobile')
  # [...]
###################################
LinkableWidget = Marionette.Behavior.extend(
  ui:
    triggersRadio: "input.link-type"
    linkDestination: ".url-destination-input"
    scrollDestination: ".scroll-destination-input"
    childPages: "select.existing-childpages"

  events:
    "click @ui.triggersRadio": "switchLinkingType"
    "blur @ui.linkDestination": "updateProtocolLink"
    "blur @ui.scrollDestination": "updateScrollLink"
    "change @ui.childPages": "changeChildPage"

  onRender: ->
    # protocol-link init
    if @view.model.get('options').prefix then @setProtocolLink(@view.model.get('options').links[@linkType()])
    else @$el.find(@ui.linkDestination).prop('disabled', true) unless @linkType() is 'url' # default is url
    # scroll-to-link init
    if @view.model.get('options').scrollTo then @setScrollingLink(@view.model.get('options').links[@linkType()])
    else @$el.find(@ui.scrollDestination).prop('disabled', true)
    @bindURLCheck(@$el.find('.url-destination-input'))

  bindURLCheck: ($input) ->
    originalVal = $input.val()
    @replaceInvalidUrl($input) # temp validation onRender for already existing links with https://
    if originalVal isnt $input.val() then $input.blur()
    $input.on 'input', => @replaceInvalidUrl($input)
  # [...]
##################################################################
# Views (Widgets)
##################################################################
@SocialPro.module 'Widgets', (Widgets, SocialPro, Backbone, Marionette, $, _) ->
  class Widgets.BaseWidgetView extends SocialPro.Views.ItemView
    ui:
      conversionGoals: "select.js-select-conversion-goals" # used in ConversionGoalConcern
      newConversionGoalInput: ".input-conversion-goal"
      widgetFocus: ".widget-focus" # this class should be added to the container div in a widget

    modelEvents:
      'change:layer': 'updateLayerIndex'

    events:
      'click .conversion-create': 'createConversionGoal'
      'click .js-conversion-destroy button': "destroyCurrentConversionGoal"
      'mousedown .js-conversion-tab': "conversionTabClickHandler"
      'change @ui.conversionGoals': "setConversionGoal"
      "click @ui.widgetFocus": "focusWidget" # redefine on widget if custom behavior is needed

    @include SocialPro.Widgets.ConversionGoalConcern

    initialize: ->
      @regionSelector = '.builder-region'
      if (this.events)
        this.events = _.defaults(this.events, Widgets.BaseWidgetView.prototype.events)
      if (this.ui)
        this.ui = _.defaults(this.ui, Widgets.BaseWidgetView.prototype.ui)
      this.delegateEvents(this.events)
      @makeWidgetDragable()
      @makeWidgetResizable()
    # [...]
#####################################################################
@SocialPro.module 'Widgets', (Widgets, SocialPro, Backbone, Marionette, $, _) ->
  class Widgets.MapWidgetView extends Widgets.BaseWidgetView
    template: "socialpro/modules/_widgets/templates/map_widget"

    behaviors:
      CopyableWidget: {}
      EmbeddableWidget: {}

    ui:
      mapTypeInput: '.map-type-input'
      mapZoomInput: '.map-zoom-input'

    events:
      "change @ui.mapTypeInput": 'setMapType'
      "change @ui.mapZoomInput": 'setMapZoom'

    setMapType: ->
      val = @$el.find(@ui.mapTypeInput).val()
      @model.setOption('mapType', val)
      @triggerMethod('render', @)

    setMapZoom: ->
      val = @$el.find(@ui.mapZoomInput).val()
      @model.setOption('mapZoom', val)
      @$el.find('.map-zoom').text(val)
      @triggerMethod('render', @)

    embeddableElement: (address) ->
      return unless address && address != ''
      type = @model.get('options').mapType
      zoom = @model.get('options').mapZoom
      "<iframe width='100%' height='100%' src='#{window.location.protocol}//maps.google.com/maps?hl=en&q=#{address}&ie=UTF8&t=#{type}&z=#{zoom}&iwloc=B&output=embed' frameborder='0'></iframe>"
#####################################################################################
# Models (Widgets)
#####################################################################################
@SocialPro.module 'Widgets', (Widgets, SocialPro, Backbone, Marionette, $, _) ->

  class Widgets.ImageWidget extends SocialPro.Entities.BaseWidget

    defaults: ->
      name: 'ImageWidget'
      type: 'img-widget'
      css: {'width': '150px', 'height': '150px', 'display': 'block'}
      src: '/images/placeholder.png'
      background_color: ''
      clip_left: ''
      clip_top: ''
      clip_zoom: ''
      crop_data: {x: 0, y: 0, width: 150, height: 150, rotate: 0}
      opacity: '1.0'
      options: {linkedWidget: ''}

    initialize: (attrs, opts) ->
      super(attrs, opts)
      if @isNew() then @set 'css', _.extend(@get('css'), opts.css)

    imageExists: =>
      (@get("src") && (@get('src').indexOf('placeholder') < 0)) || !!@getOriginalImageSrc()
  # [...]
#################################################################################
# Views (Analytics)
#################################################################################
@SocialPro.module 'Analytics', (Analytics, SocialPro, Backbone, Marionette, $, _) ->

  class Analytics.PageTableRowView extends SocialPro.Views.ItemView
    template: "modules/analytics/templates/page_table_row"
    tagName: "tr"

    events:
      "click .js-ab-priority, .js-eip-icon": "editInPlacePriority"
      "keypress .js-eip-priority": "changePriority"
      "mouseover .js-ab-priority": "showEiPIcon"
      "mouseleave .js-ab-priority": "hideEiPIcon"
      "click .js-set-as-original": "setAsOriginal"

    initialize: (options) =>
      @searchBarChannel = SocialPro.Radio.channel('analytics-search-bar')

    showEiPIcon: (e) => @$el.find('.js-eip-icon').show()

    hideEiPIcon: (e) => @$el.find('.js-eip-icon').hide()
    # [...]
    onBeforeRender: =>
      dropdownTemplate = "modules/analytics/templates/_dropdown_menu"
      if !@model.get('_summary')
        @model.set("dropdownMenuTemplate", Marionette.Renderer.render(dropdownTemplate, @model.toJSON()))

    onRender: =>
      @$el.find('.js-set-priority').off()
      @$el.find('.js-set-priority').on 'click', @editInPlacePriority

  class Analytics.PageTableView extends SocialPro.Views.CompositeView
    template: "modules/analytics/templates/page_table"
    childView: Analytics.PageTableRowView

    initialize: (options) =>
      @summary = options.summary
      @collection.on 'reset', @render, this

    attachBuffer: (collectionView, buffer) =>
      collectionView.$el.find(".js-main-tbody").append(buffer)
#################################################################################
# Views (main view - canvas)
#################################################################################
@SocialPro.module 'Apps', (Apps, SocialPro, Backbone, Marionette, $, _) ->

  # class Apps.Container extends SocialPro.Views.ItemView
  #
  #   template: 'modules/apps/templates/_container'
  #   onRender: -> (SocialPro.Widgets.ViewFactory.get(@model.get('type'), @model)).render()

  class Apps.Canvas extends SocialPro.Views.CollectionView
    @include SocialPro.Concerns.CanvasEventsChannel

    builderChannel: Backbone.Radio.channel('builder')
    el: '#editor-canvas'
    childView: SocialPro.Widgets.BaseWidgetView
    collectionEvents:
      'add'     : (model) -> @builder.widgetAdded(model)
      'change'  : (model) -> @builder.widgetChanged(model)

    initialize: (options) ->
      @builder = @options.builder
      @page = @model
      @widgets = @collection
      @bindWidgetDragAndDrop()
      @bindDeleteKey()
      @bindEventChannel()
      @conversionGoals = new SocialPro.Entities.ConversionGoals([], {pageVariantID: @page.get("page_variant_id")})
      @conversionGoals.fetchRecords()

    onRender: -> @widgets.each (widget) => @afterWidgetRender(widget)

    afterWidgetRender: (widget) -> # Sort for mobile algorithm and canvas height update
      @canvasHeightCheck(widget)
      if (!widget.get('sorted') or parseInt(widget.get('css').left) > 320) and widget.get('device_type') is 'mobile'
        @mobileSort = true
        @mobileSorting(widget)

    filter: (widget, index, collection) ->
      return widget.get('device_type') is @builder.device and not widget.get('destroyed')

    buildChildView: (widget, ChildViewClass, childViewOptions) ->
      container = JST['socialpro/modules/apps/templates/_container'](widget.attributes)
      @$el.append $(container).css(widget.get('css'))
      SocialPro.Widgets.ViewFactory.get(widget.get('type'), widget)
    # [...]
#########################################################################################
