/////////////////////////////////////////////////////////////////////
// AngularJS
/////////////////////////////////////////////////////////////////////
this.NavbarCtrl = function($scope, $http, CurrentUser) {
  $scope.user = CurrentUser.get();
}

this.MainCtrl = [
  "$scope", "List", "Task", function($scope, List, Task) {
    $scope.lists = List.query();

    $scope.addList = function() {
      var list = List.save($scope.newList);
      $scope.lists.push(list);
      return $scope.newList = {};
    }

    $scope.updateList = function(list) {
      List.update({id: list.id, list: {name: list.name}});
    }
	//[...]

/////////////////////////////////////////////////////////////////////
var app = angular.module("Masters", ["ngResource", 'ngRoute', 'mk.editablespan']);

app.config([
  "$httpProvider", function($httpProvider) {
    $httpProvider.defaults.headers.common['X-CSRF-Token'] = $('meta[name=csrf-token]').attr('content');
    $httpProvider.defaults.headers.common['Accept'] = "application/json"
  }
]);

app.factory("Task", [
  "$resource", function($resource) {
    return $resource("/lists/:list_id/tasks/:id", {list_id: "@list_id", id: "@id"}, {update: {method: "PATCH"}})
  }
]);

