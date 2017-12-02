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
        journal: './frontend/journal.js',
        sorder: './frontend/sorder.js',
        vorder: './frontend/vorder.js',
        smk: './frontend/smk.js',
        vmk: './frontend/vmk.js',
        docs: './frontend/docs.js',
        doc: './frontend/doc.js',
        asutused: './frontend/asutused.js',
        kontod: './frontend/kontod.js',
        nomenclature: './frontend/nomenclature.js',
        documentLib: './frontend/documentLib.js',
        project: './frontend/project.js',
        tunnus: './frontend/tunnus.js',
        tunnused: './frontend/tunnused.js',
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
            chunks: ['docs', 'doc', 'arv', 'journal', 'sorder', 'vorder', 'smk', 'vmk', 'asutused', 'kontod', 'nomenclature', 'documentLib', 'project', 'tunnus', 'tunnused'], // список модулей для выявления общих модулей
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
