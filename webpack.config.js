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
//    context: __dirname + '/frontend',
    entry: {
        raama: './frontend/raama.js'
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
            chunks: ['raama'], // список модулей для выявления общих модулей
            minChunks: 2
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
