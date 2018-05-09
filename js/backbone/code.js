/////////////////////////////////////////////////////////////////////
// Backbone.js
/////////////////////////////////////////////////////////////////////
App.Views.CreateAdministrationSubscriptionModal = Backbone.View.extend({
  className: 'modal fade',
  id: 'createAdministrationSubscriptionModal',

  initialize: function (options) {
    _.bindAll(this, 'remove');
    this.template = JST['backbone/templates/create_administration_subscription_modal'];

    this.userType = options.userType;
    this.model = new App.Models.AdministrationSubscription({
      administration_id: options.administration_id
    });

    this.render();
    this.bindEvents();
  },

  bindEvents: function () {
    this.listenTo(this.model, 'change', this.handleModelChange);
    this.listenTo(this.model, 'request', this.handleModelRequest);
    this.listenTo(this.model, 'sync', this.handleModelSaved);
    this.listenTo(this.model, 'error', this.handleModelSaveError);
  },

  render: function() {
    this.$el.html(this.template({
      userType: this.userType
    }));

    this.renderSearchCandidatesView();

    this.$el.modal();
    this.$el.on('hidden.bs.modal', this.remove);
  },

  renderSearchCandidatesView: function () {
    return new App.Views.SearchSubscriptionCandidates({
      userType: this.userType,
      model: this.model,
      el: this.$el.find('.modal-body')
    });
  },

  handleModelChange: function () {
    if (this.model.isValid() && this.model.isNew()) {
      this.model.save();
    }
  },
//[..]

/////////////////////////////////////////////////////////////////////

App.Views.SearchSubscriptionCandidatesResults = Backbone.View.extend({

  events: {
    'click .users-list > li': 'handleUserListItemClick'
  },

  initialize: function() {
    this.template = JST['backbone/templates/search_subscriptions_candidates_results'];

    this.listenTo(this.collection, 'reset', this.render);
    this.listenTo(this.collection, 'request', this.renderLoadingView);
  },

  render: function () {
    this.$el.html(this.template({
      collection: this.collection
    }));
  },

  renderLoadingView: function () {
    this.$el.html((new App.Views.LoadingAnimation()).$el);
  },

  handleUserListItemClick: function (e) {
    var $elem = $(e.target).closest('li'),
      userId = $elem.data('userid');

    this.$el.find('.active').removeClass('active');
    $elem.addClass('active');

    this.model.set("user_id", userId);
  }
});

