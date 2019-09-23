'use strict';
const axios = require('axios');
//axios.defaults.baseURL = 'http://localhost:3000';
axios.defaults.baseURL = '/';

module.exports =  {
    fetchDataGet(url) {
        return axios.get(url)
            .then(res => res)
            .catch(error => console.error('fetchDara error', error))
    },
    fetchDataPost(url, params) {
        return axios.post(url, params)
            .then(res => {
                return res;
            })
            .catch(error => console.error('fetchData error'))
    },
    fetchDataPut(url, params) {
        return axios.put(url, params)
            .then(res => {
                return res;
            })
            .catch(error => console.error('fetchData error'))
    },

};
