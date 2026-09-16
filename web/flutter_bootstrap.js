{{flutter_js}}
{{flutter_build_config}}

// Load the renderer from the build, not from a public CDN.
_flutter.loader.load({
  config: { canvasKitBaseUrl: 'canvaskit/' }
});
