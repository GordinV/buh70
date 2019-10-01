'use strict';
const axios = require('axios');
//axios.defaults.baseURL = 'http://localhost:3000';
axios.defaults.baseURL = '/';

module.exports = {
    fetchDataGet(url) {
        return axios.get(url)
            .then(res => res)
            .catch(error => {
                console.error('fetchDara error', error);
                return ({result: 'error', status: 401});
            })
    },
    fetchDataPost(url, params) {
        return axios.post(url, params)
            .catch(error => {
                console.error('fetch error', error);
                return ({result: 'error', status: 401});
            })
    },
    fetchDataPut(url, params) {
        return axios.put(url, params)
            .catch(error => console.error('fetchData error', error))
    },

};
