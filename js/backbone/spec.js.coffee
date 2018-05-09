####################################################
# gem used for testing: https://github.com/bradphelan/jasminerice
####################################################

####################################################
# /spec/javascripts/collections/
####################################################

class SI.FakeAdvancedPaginatedCollection extends SI.AdvancedPaginatedCollection
  resourceUri: 'models'

describe 'SI.AdvancedPaginatedCollection', ->

  describe '#url', =>

    it 'should return api url', =>
      collection = new SI.FakeAdvancedPaginatedCollection()
      expect(collection.url()).toBe("#{SI.url}/#{collection.resourceUri}?page=1")

  describe '#urlForSearch', =>

    beforeEach ->
      @collection = new SI.FakeAdvancedPaginatedCollection()
      @urlStub = "#{SI.url}/models?utf8=%E2%9C%93&query=erogata&type=sentence&page=1"
      @serializedForm = "utf8=%E2%9C%93&query=erogata&type=sentence"

    describe 'current_page = 1', ->
      it 'should return URL for search', ->
        @collection.current_page = 1
        expect(@collection.urlForSearch(@serializedForm)).toBe(@urlStub)

    describe 'current_page is not explicity set', ->
      it 'should return URL for search', ->
        expect(@collection.urlForSearch(@serializedForm)).toBe(@urlStub)

####################################################

describe 'SI.Collections.Decree', ->

  it 'should de defined', ->
    expect(SI.Collections.DecreeList).toBeDefined()

  it 'can be instantianed', ->
    expect(new SI.Collections.DecreeList()).not.toBeNull()

  beforeEach ->
    this.decrees = new SI.Collections.DecreeList()

  describe '#fetch', ->
    beforeEach ->
      this.server = sinon.fakeServer.create()

    afterEach ->
      this.server.restore()

    describe 'request', ->
      beforeEach ->
        this.decrees.fetch()
        this.request = this.server.requests[0]

      it 'should be GET', ->
        expect(this.request).toBeGET()

      it 'should be async', ->
        expect(this.request).toBeAsync()

      it 'should have valid URL', ->
        expect(this.request).toHaveUrl(SI.urlFor("decrees", {page: 0}))
####################################################
# /spec/javascripts/models/
####################################################	
describe 'SI.Models.Decree', ->
  it 'should be defined', ->
    expect(SI.Models.Decree).toBeDefined()

  it 'can be instantiated', ->
    expect(new SI.Models.Decree()).not.toBeNull()

  describe '#urlRoot attribute', ->
    it 'has default value', ->
      decree = new SI.Models.Decree()
      expect(decree.urlRoot).toEqual(SI.urlFor("decrees"))

  describe '#body', ->
    it 'should join Decree articles and return them', ->
      decree = new SI.Models.Decree()
      article = body: "|Lorem ipsum."
      decree.set("articles", [article, article])
      expect(decree.body()).toEqual("|Lorem ipsum.|Lorem ipsum.")
####################################################
# /spec/javascripts/views/
####################################################
describe 'SI.Views.SearchYearsRange', ->

  beforeEach ->
    loadFixtures("sentences/_search_years_filters.html")

  it 'should be defined', ->
    expect(SI.Views.SearchYearsRange).toBeDefined()

  it 'can be instantianed', ->
    expect(new SI.Views.SearchYearsRange()).not.toBeNull()

  beforeEach ->
    @view = new SI.Views.SearchYearsRange()

  describe 'getStartDate', ->
    it 'calculates start date', ->
      expect(@view.getStartDate(2013).getFullYear()).toBe(new Date(2013, 0).getFullYear())
      expect(@view.getStartDate(1978).getFullYear()).toBe(new Date(1978, 0).getFullYear())

  describe 'getEndDate', ->
    it 'calculates end date', ->
      currentDate = new Date()
      expect(@view.getEndDate(currentDate.getFullYear()).getMonth()).toBe(new Date().getMonth())
      expect(@view.getEndDate(currentDate.getFullYear()).getFullYear()).toBe(new Date().getFullYear())

      lastYearDate = new Date(2012, 11, 31)
      expect(@view.getEndDate(2012).getFullYear()).toBe(lastYearDate.getFullYear())
      expect(@view.getEndDate(2012).getMonth()).toBe(lastYearDate.getMonth())
      expect(@view.getEndDate(2012).getDate()).toBe(lastYearDate.getDate())
####################################################
