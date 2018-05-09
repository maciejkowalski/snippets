import ReceivingModule from './receiving'

describe('Receiving', () => {
  let $rootScope, $state, $location, $componentController, $compile;

  beforeEach(window.module(ReceivingModule));

  beforeEach(inject(($injector) => {
    $rootScope = $injector.get('$rootScope');
    $componentController = $injector.get('$componentController');
    $state = $injector.get('$state');
    $location = $injector.get('$location');
    $compile = $injector.get('$compile');
  }));

  describe('Module', () => {
    // top-level specs: i.e., routes, injection, naming
    it('default component should be receiving', () => {
      $location.url('/');
      $rootScope.$digest();
      expect($state.current.component).to.eq('receiving');
    });
  });

  describe('View', () => {
    // view layer specs.
    let scope, template;

    beforeEach(() => {
      scope = $rootScope.$new();
      template = $compile('<receiving></receiving>')(scope);
      scope.$apply();
    });

    it('has name in template', () => {
      expect(template.find('h1').html()).to.eq('Found in receiving.html');
    });
  // [...]
