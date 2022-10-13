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
            panels: [],
        },
}
