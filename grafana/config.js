define(['settings'], function (Settings) {
  return new Settings({
    elasticsearch: '/elasticsearch',
    graphiteUrl: '/graphite',
    default_route: '/dashboard/file/default.json',
    timezoneOffset: '0000',
    grafana_index: 'grafana-dash',
    panel_names: [ 'text', 'graphite' ]
  });
});

