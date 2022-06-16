const createEmptyFilterData = require('./../libs/createEmptyFilterData');

const DocContext = {
    filter: {},
    libs: {},
    menu: [],
    initData: [],
    docTypeId: 'LAPS',
    userData: {},
    module: 'lapsed',
    pageName: 'Laste register',
    gridConfig: {},
    filterValidation: {
        PAEVA_TAABEL: (data) => {
            // контроль на данные одного дня
            let errorMessage = '';
            data.forEach((filterData) => {
                switch (filterData.id) {
                    case 'kpv':
                        if (filterData.start && filterData.end && (new Date(filterData.start) > new Date(filterData.end))) {
                            errorMessage = errorMessage + 'Alg. kuupäev ei tohi olla hiljem kui lõpp kuupäaev;';
                        }
                        break;
                    default:
                        // ничего
                        break;
                }
            });
            return errorMessage;
        },
        LAPS: (data) => {
            // контроль на данные одного дня
            let errorMessage = '';
            data.forEach((filterData) => {
                switch (filterData.id) {
                    case 'period':
                        if (filterData.start && filterData.end && (filterData.start === filterData.end)) {
                            errorMessage = errorMessage + 'Alg. ja lõpp kuupäev ei tohi olla võrdsed;';
                        }
                        break;
                    default:
                        // ничего
                        break;
                }
            });
            return errorMessage;
        },
        LAPS_KOKKUVOTTE: (data) => {
            // контроль на данные одного дня
            let errorMessage = '';
            // нужно имя или личн. код
            let isMinimumDataAvailable = false;
            data.forEach((filterData) => {
                switch (filterData.id) {
                    case 'lapse_isikukood':
                        if (filterData.value && filterData.value != '%') {
                            isMinimumDataAvailable = true;
                        }
                        break;
                    case 'lapse_nimi':
                        if (filterData.value && filterData.value != '%') {
                            isMinimumDataAvailable = true;
                        }
                        break;
                    case 'kpv':
                        if (filterData.start && filterData.end && (new Date(filterData.start) > new Date(filterData.end))) {
                            errorMessage = errorMessage + 'Alg. kuupäev ei tohi olla hiljem kui lõpp kuupäaev;';
                        }
                        break;
                    default:
                        // ничего
                        break;
                }
            });

            if (!isMinimumDataAvailable) {
                errorMessage = 'Isikukood või nimi on kohustlik;';
            }
            // какой-то параметр есть, добавим % для пустого
            data = data.map(row => {
                if (row.id === 'lapse_isikukood' && (!row.value || row.value == '%')) {
                    row.value = isMinimumDataAvailable  ? '%': '';
                }

                if (isMinimumDataAvailable && row.id === 'lapse_nimi' && (!row.value || row.value == '%')) {
                    row.value = isMinimumDataAvailable ? '%': '';
                }

                return row;
            });
            return errorMessage;
        },

    },
    accessCode: {},
    'email-params': {},
    /**
     * setter setinitData
     * @param data
     */
    set setInitData(data) {
        this.initData = data;
        this.setGridConfig = data.docConfig;
        this.menu = data.menu ? data.menu.data : [];
    },


    /**
     * сохранит код доступа и факт его акцептации для пользователя
     * @param userName
     */
    set setAccessCode(userName) {
        if (!this.accessCode[userName]) {
            this.accessCode[userName] = {
                accessCode: null,
                accepted: null
            }
        }
    },

    // проверит и сохранит отметку о подтверждении кода доступа
    acceptAccessCode(userName, accessCode) {
        if (this.accessCode[userName].accessCode == accessCode) {
            this.accessCode[userName].accepted = new Date().getDate();
            return true;
        } else {
            return false;
        }
    },

    /**
     * setter userData
     * @param user
     */

    set setUserData(user) {
        this.userData = user;
    },

    /**
     * setter module
     * @param module
     */
    set setModule(module) {
        this.module = module;
    },

    set setPageName(page) {
        this.pageName = page;
    },

    set setGridConfig(config) {
        this.gridConfig = config;
    },

    set setFilter(filter) {
        this.filter[this.docTypeId] = filter;
    },

    set setDocTypeId(docTypeId) {
        this.docTypeId = docTypeId;

        // инициализируем последнее ИД
        this[this.docTypeId.toLowerCase()] = this[this.docTypeId] ? this[this.docTypeId] : 0;

        // Название страницыиз меню
        let menuRow = this.menu ? this.menu.find(row => row.kood === this.docTypeId) : null;

        if (menuRow) {
            this.pageName = menuRow.name;
        }

        // set Filter
        if (!this.getFilter) {
            this.filter[this.docTypeId] = [];
        }
    },

    set setLib(data) {
        this.libs = Object.assign({}, this.libs, data);
    },

    set setEmailParams(params) {
        this["email-params"] = params;
    },

    set setDocId(id) {
        this[this.docTypeId.toLowerCase()] = id;
    },

    set setMenu(data) {
        this.menu = data;
    },

    /**
     * getter for rekvId
     * @returns {null|*}
     */

    get getAsutusId() {
        if (this.userData && this.userData.asutusId) {
            return this.userData.asutusId;
        } else {
            return null;
        }
    },

    get getDocTypeId() {
        return this.docTypeId;
    },

    get getUuid() {
        return this.userData && this.userData.uuid ? this.userData.uuid : null;
    },

    get getUserId() {
        return this.userData && this.userData.userId ? this.userData.userId : null;
    },

    get getUserName() {
        return this.userData && this.userData.userName ? this.userData.userName : '';
    },

    get getGridConfig() {
        return this.gridConfig && this.gridConfig[this.docTypeId] ? this.gridConfig[this.docTypeId] : [];
    },

    get getFilter() {
        return this.filter && this.filter[this.docTypeId] ? this.filter[this.docTypeId] : [];
    },

    get getRoles() {
        return this.userData ? this.userData.roles : [];
    },

    get getLib() {
        return this.libs[this.docTypeId.toLowerCase()];
    },

    get getModule() {
        return this.module;
    },

    get getMenu() {
        return this.menu;
    },

    get getPageName() {
        return this.pageName;
    },

    getAccessCode(userName) {
        // создадим обект пользователя
        if (!this.accessCode[userName]) {
            this.setAccessCode = userName;
        }

        // генерация кода доступа, если не акцептирован или акцептирован не сегодня
        if (!this.accessCode[userName].accessCode || !this.accessCode[userName].accepted || this.accessCode[userName].accepted !== new Date().getDate()) {
            // обнуляем код доступа
            let min = Math.ceil(1000);
            let max = Math.floor(9999);
            this.accessCode[userName].accessCode = Math.floor(Math.random() * (max - min) + min);
        }

        return this.accessCode[userName].accessCode;
    }


};


module.exports = (DocContext);