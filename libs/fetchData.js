'use strict';
const axios = require('axios');
axios.defaults.baseURL = '/';
let isOk = false;

module.exports = {
    fetchDataGet(url) {
        return axios.get(url)
            .then(res => res)
            .catch(error => {
                console.error('fetchData status, error', error.response.status, error);
                return ({result: 'error', status: error.response.status});
            })
    },
    fetchDataPost(url, params) {
        return axios.post(url, params)
            .then(res => {
                return res;
            })
            .catch(error => {
                console.error('fetchData error', error);
                return ({
                    result: 'error',
                    status: error.response && error.response.status ? error.response.status : 500
                });
            })
    },
    fetchDataPut(url, params) {
        return axios.put(url, params)
            .catch(error => {
                console.error('fetchData error', error.response.status, error);
                return ({result: 'error', status: error.response.status});
            })
    },

};
