/////////////////////////////////////////////////////////////////////
// Ember.js
/////////////////////////////////////////////////////////////////////
window.EmTasks = Ember.Application.create({
  rootElement: "#root-container"
})

/////////////////////////////////////////////////////////////////////

EmTasks.ListsRoute = Ember.Route.extend({
  model: function() {
    return this.store.find('list');
  }
});

/////////////////////////////////////////////////////////////////////

EmTasks.ListsController = Em.ArrayController.extend({
  addList: function() {
    this.store.createRecord('list', {
      name: this.get('newListName')
    }).save();
    return this.set('newListName', '');
  },

  destroyList: function(id) {
    if (confirm("Are you sure?")) {
      this.get('store').find('list', id).then( function(record) {
        record.destroyRecord();
      });
    }
  },
});

/////////////////////////////////////////////////////////////////////

EmTasks.TaskController = Em.ObjectController.extend({
  actions: {
    editTask: function() {
      this.set('isEditingTask', true);
    },

    acceptChanges: function() {
      this.set("isEditingTask", false);
      var name = this.get('model.name');

      if (Ember.isEmpty(name)) {
        this.send('removeTask');
      } else {
        var task = this.get('task');
        task.set('name', name);
        task.save()
      }
    },
	//[...]

/////////////////////////////////////////////////////////////////////

EmTasks.Task = DS.Model.extend({
  name: DS.attr('string'),
  description: DS.attr("string"),
  list: DS.belongsTo('list')
});

/////////////////////////////////////////////////////////////////////

EmTasks.EditInputView = Ember.TextField.extend({
  didInsertElement: function () {
    this.$().focus();
  }
});

Ember.Handlebars.helper('edit-input', EmTasks.EditInputView);

