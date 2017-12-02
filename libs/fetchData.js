'use strict';
const axios = require('axios');
axios.defaults.baseURL = 'http://localhost:3000'

module.exports =  {
    fetchDataGet(url) {
        return axios.get(url)
            .then(res => res)
            .catch(error => console.error('fetchDara error', error))
    },
    fetchDataPost(url, params) {
        return axios.post(url, params)
            .then(res => {
                console.log('receved vastus:', res);
                return res;
            })
            .catch(error => console.error('fetchData error', error))
    },

};
