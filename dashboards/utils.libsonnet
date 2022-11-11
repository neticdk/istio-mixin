(import 'github.com/grafana/jsonnet-libs/grafana-builder/grafana.libsonnet') {
    row(title=''):: {
        addPanel(panel):: self {
            panels+: [panel],
        },
        collapsed: false,
        panels: [],
        title: title,
        type: "row"
    },

    statPanel(title, query, unit='short', instant=true):: {
        type: "stat",
        title: title,
        datasource: {
            uid: "$datasource"
        },
        targets: [{
            expr: query,
            format: "time_series",
            instant: instant,
            intervalFactor: 2,
            refId: "A",
            datasource: {
                uid: "$datasource"
            }
        }],
        fieldConfig: {
            defaults: {
                mappings: [],
                thresholds: {
                    mode: "absolute",
                    steps: [],
                },
                unit: unit,
                color: {
                    mode: "thresholds"
                }
            },
            overrides: []
        },
        options: {
            reduceOptions: {
                values: false,
                calcs: ["mean"],
                fields: "",
            },
            orientation: "horizontal",
            textMode: "auto",
            colorMode: "none",
            graphMode: "area",
            justifyMode: "auto"
        },
    },

    dashboard(title, uid='', datasource='default', datasource_regex=''):: 
        super.dashboard(title, uid, datasource, datasource_regex) + {
            addRow(row):: self {
                local pan = row.panels,
                panels+: [row { panels: [] }] + pan,
            },
            addTemplate(name, metric_name, label_name, hide=0, allValue=null, includeAll=false):: self {
                templating+: {
                    list+: [{
                    allValue: allValue,
                    current: {
                        text: 'prod',
                        value: 'prod',
                    },
                    datasource: '$datasource',
                    hide: hide,
                    includeAll: includeAll,
                    label: name,
                    multi: false,
                    name: name,
                    options: [],
                    query: if metric_name == null then 'label_values(%s)' % label_name else 'label_values(%s, %s)' % [metric_name, label_name],
                    refresh: 1,
                    regex: '',
                    sort: 2,
                    tagValuesQuery: '',
                    tags: [],
                    tagsQuery: '',
                    type: 'query',
                    useTags: false,
                    }],
                },
            },
            addQueryTemplate(name, query, regex='', includeAll=false, multi=false, includeAll=false):: self {
                templating+: {
                    list+: [{
                    allValue: null,
                    current: {},
                    datasource: '$datasource',
                    hide: 0,
                    includeAll: includeAll,
                    label: name,
                    multi: multi,
                    name: name,
                    options: [],
                    query: 'query_result(%s)' % query,
                    refresh: 1,
                    regex: regex,
                    sort: 2,
                    tagValuesQuery: '',
                    tags: [],
                    tagsQuery: '',
                    type: 'query',
                    useTags: false,
                    }],
                },
            },
            panels: [],
        },
}
