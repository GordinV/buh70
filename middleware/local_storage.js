module.exports = {
    libs: [],

/*
    if (req.session.libs) {
        console.log('есть данные в кеше')
        libs = req.session.libs;
    };
*/

    getLib: function(lib) {
        // вернет данные из кеша
        var returnData = this.libs.filter(function(item) {
            if (item.id == lib) {
                return item;
            }
        })

        return returnData[0] || null;
    },

    setLib: function(lib, data, req) {
        var libs = this.libs,
            found = false;
        console.log('setLib:' + JSON.stringify(data));
        //пишет данные в кеш
        // 1. ищем справочник в кеше
        libs.map(function(item) {
            if (item.id == lib) {
                // 3. иначе замещаем данные
                found = true; // поиск был успешен
                item.data = data;
            }
            return item;
        });

        // 2. если нет добавляем в массив
        if (!found) {
            // не нашли справочник, добавляем в массив
            libs.push({id:lib, data: data});
        };

        // 4. сохраняем в сессии
        req.session.libs = libs;
    }
};
