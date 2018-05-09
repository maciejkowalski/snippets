/////////////////////////////////////////////////////////////////////
// testing Backbone.js with Jasmine
/////////////////////////////////////////////////////////////////////
describe("App.Views.SearchSubscriptionCandidates", function () {
  var view,
    initView = function () {
      return new App.Views.SearchSubscriptionCandidatesResults({
        model: new App.Models.AdministrationSubscription({
          administration_id: 3
        }),
        collection: new App.Collections.AdministrationSubscriptionCandidates([], {
          administration_id: 3
        })
      });
    };

  describe("events", function () {
    afterEach(function () {
      tearDownView(view);
    });

    describe("collection reset", function () {
      beforeEach(function () {
        spyOn(App.Views.SearchSubscriptionCandidatesResults.prototype, 'render');
        view = initView();
        view.collection.trigger('reset');
      });

      it("renders the view", function () {
        expect(App.Views.SearchSubscriptionCandidatesResults.prototype.render).toHaveBeenCalled();
      });
    });

    describe("collection request", function () {
      beforeEach(function () {
        spyOn(App.Views.LoadingAnimation.prototype, 'render');
        view = initView();
        view.collection.trigger('request');
      });

      it("renders the loading boxes", function () {
        expect(App.Views.LoadingAnimation.prototype.render).toHaveBeenCalled();
      });
    });

    describe("click on user list item", function () {
      var firstLi,
        lastLi;

      beforeEach(function () {
        view = initView();
        view.$el.appendTo('body');
        view.collection.reset([{
          id: 1
        }, {
          id: 2
        }]);
        firstLi = view.$el.find(".users-list > li:first-child");
        lastLi = view.$el.find(".users-list > li:last-child");
        firstLi.addClass("active");
        lastLi.click();
      });

      it("adds .active class to the clicked li", function () {
        expect(lastLi.hasClass('active')).toBe(true);
      });

      it("removes .active from existing li-s", function () {
        expect(firstLi.hasClass('active')).toBe(false);
      });

      it("sets the user id on the model", function () {
        expect(view.model.get("user_id")).toEqual(2);
      });
    });
	//...
/////////////////////////////////////////////////////////////////////
describe("App.Views.SearchSubscriptionCandidates", function () {
  var view,
    initView = function () {
      return new App.Views.SearchSubscriptionCandidates({
        model: new App.Models.AdministrationSubscription({
          administration_id: 3
        }),
        userType: "external"
      });
    };

  describe("initialize", function () {
    beforeEach(function () {
      spyOn(App.Views.SearchSubscriptionCandidates.prototype, 'render').and.callThrough();
      spyOn(App.Views.SearchSubscriptionCandidatesResults.prototype, 'initialize').and.callThrough();
      view = initView();
    });

    it("has a template", function () {
      expect(view.template).toEqual(JST['backbone/templates/search_subscription_candidates']);
    });

    it("renders on initialize", function () {
      expect(App.Views.SearchSubscriptionCandidates.prototype.render).toHaveBeenCalled();
    });

    it("inits a new candidates collection", function () {
      expect(view.collection.constructor).toEqual(App.Collections.AdministrationSubscriptionCandidates);
      expect(view.collection.isEmpty()).toBe(true);
      expect(view.collection.administration_id).toEqual(3);
    });

    it("assigns userType", function () {
      expect(view.userType).toEqual("external");
    });

    it("inits SearchSubscriptionCandidatesResults view", function () {
      var sut = App.Views.SearchSubscriptionCandidatesResults.prototype.initialize,
        args;
      expect(sut).toHaveBeenCalled();
      args = sut.calls.argsFor(0)[0];
      expect(args.collection).toEqual(view.collection);
      expect(args.model).toEqual(view.model);
      expect(args.el).toEqual(view.$('.search-results'));
    });
  });
  //...
