local dashboards = (import 'mixin.libsonnet').grafanaDashboards;

{
  ["dashboard-%s" % name]: std.manifestJson(dashboards[name]) for name in std.objectFields(dashboards)
}
