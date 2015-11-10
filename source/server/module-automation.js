Space.Module.mixin({

  Routers: [],
  Projections: [],

  onDependenciesReady: function() {
    this._wrapLifecycleHook('onInitialize', this._onInitializeEventSourcing);
    this._wrapLifecycleHook('onStart', this._onStartEventSourcing);
  },

  _onInitializeEventSourcing: function(onInitialize) {
    var module = this;
    onInitialize.call(module);
    _.each(_.union(module.Routers, module.Projections), function(singleton) {
      module.injector.map(singleton).asSingleton();
    });
  },

  _onStartEventSourcing: function(onStart) {
    var module = this;
    onStart.call(module);
    _.each(_.union(module.Routers, module.Projections), function(singleton) {
      module.injector.create(singleton);
    });
  }

});
