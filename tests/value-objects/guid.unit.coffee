describe "Guid", ->

  # =============== CONSTRUCTION ================ #

  describe 'construction', ->

    it 'is serializable', ->
      guid = new Guid()
      copy = EJSON.parse EJSON.stringify(guid)
      expect(copy.equals(guid)).to.be.true;

    it 'generates a globally unique id', ->

      guid = new Guid()
      expect(guid.valueOf()).to.match Guid.REGEXP
      expect(guid.toString()).to.match Guid.REGEXP

    it 'optionally assigns a given id', ->

      id = '936DA01F-9ABD-4D9D-80C7-02AF85C822A8'
      guid = new Guid(id)
      expect(guid.valueOf()).to.equal id
      expect(guid.toString()).to.equal id

    it 'checks given id to be compliant', ->
      expect(-> new Guid('123')).to.throw()

  # =============== EQUALITY ================ #

  describe 'equality', ->

    it 'is equal when same id', ->

      guid1 = new Guid()
      guid2 = new Guid guid1
      expect(guid1.equals(guid2)).to.be.true

    it 'is equal when same id', ->

      guid1 = new Guid()
      guid2 = new Guid()
      expect(guid1.equals(guid2)).to.be.false

  # =============== IMMUTABILITY ================ #

  describe 'immutability', ->

    it 'freezes itself', -> expect(Object.isFrozen(new Guid())).to.be.true
