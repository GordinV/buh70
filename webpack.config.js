var path = require('path');
const webpack = require('webpack');

//const NODE_ENV = process.env.NODE_ENV || 'development';
const NODE_ENV = 'development';
//const NODE_ENV = 'production';

/*
 if (!DEBUG) {
 plugins.push(
 new webpack.optimize.UglifyJsPlugin()
 );
 }
 */

module.exports = {
    //entry: './frontend/docs.js',
//    context: __dirname + '/frontend',
    entry: {
        arv: './frontend/arv.js',
        arv_register: './frontend/arv-register.js',
        journal: './frontend/journal.js',
        journal_register: './frontend/journal-register.js',
        sorder: './frontend/sorder.js',
        sorder_register: './frontend/sorder-register.js',
        vorder: './frontend/vorder.js',
        vorder_register: './frontend/vorder-register.js',
        smk: './frontend/smk.js',
        smk_register: './frontend/smk-register.js',
        vmk: './frontend/vmk.js',
        vmk_register: './frontend/vmk-register.js',
        docs: './frontend/docs.js',
        docs_register: './frontend/docs-register.js',
        doc: './frontend/doc.js',
        document_register: './frontend/document-register.js',
        asutused: './frontend/asutused.js',
        asutus_register: './frontend/asutus-register.js',
        kontod: './frontend/kontod.js',
        nomenclature: './frontend/nomenclature.js',
        nomenclature_register: './frontend/nomenclature-register.js',
        documentLib: './frontend/documentLib.js',
        project: './frontend/project.js',
        projektid: './frontend/projektid.js',
        tunnus: './frontend/tunnus.js',
        tunnused: './frontend/tunnused.js',
        kontod_register: './frontend/kontod-register.js',
    },
    output: {
        path: __dirname + '/public/javascripts',
        filename: '[name].js',
        library: '[name]'
    },

    watch: NODE_ENV == 'development', // наблюдает за изменениями

    watchOptions: {
        aggregateTimeout: 300 // задержка перед сборкой после изменений
    },
    externals: {
        // Use external version of React
        "react": "React",
        "react-dom": "ReactDOM",
    },
    devtool: NODE_ENV == 'development' ? "cheap-inline-source-map" : null, // для разработки, для продакшена cheap-source-map
    stats: {
        colors: true,
        modules: true,
        reasons: true,
        errorDetails: true
    },
    plugins: [
//        new webpack.NoerrorsPlugin(),
        new webpack.DefinePlugin({NODE_ENV: JSON.stringify(NODE_ENV)}),
        new webpack.optimize.CommonsChunkPlugin({
            name: "common",
            chunks: ['docs', 'docs_register','doc', 'document_register', 'arv', 'arv_register',
                'journal', 'journal_register',
                'sorder', 'sorder_register', 'vorder','vorder_register',
                'smk', 'smk_register', 'vmk', 'vmk_register', 'asutused','asutus_register',
                'kontod','kontod_register',
                'nomenclature', 'nomenclature_register','documentLib', 'project', 'projektid', 'tunnus', 'tunnused'
                ], // список модулей для выявления общих модулей
            minChunks: 3
        })
    ],
    module: {
        loaders: [

            {
                test: /\.js$/,
                //include: __dirname + '/frontend',
                loader: 'babel-loader',
                query: {
                    compact: false,
                    plugins: ['transform-decorators-legacy', "transform-class-properties"],
                    presets: ['es2015', 'stage-0', 'react']
                }
            },

            {test: /\.jsx$/, loader: "babel"}

        ]
    }
};

if (NODE_ENV == 'production') {
    module.exports.plugins.push(
        new webpack.optimize.UglifyJsPlugin({
            compress: {
                warnings: false,
                drop_console: true,
                unsafe: true
            }
        })
    );
}
