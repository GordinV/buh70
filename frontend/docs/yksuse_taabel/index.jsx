'use strict';

const React = require('react');
const DocumentRegister = require('./../documents/documents.jsx');
const BtnGetXml = require('./../../components/button-register/button-task/index.jsx');
const ToolbarContainer = require('./../../components/toolbar-container/toolbar-container.jsx');

const styles = require('./styles');
const DOC_TYPE_ID = 'YKSUSE_TAABEL';
const DocContext = require('./../../doc-context.js');
const TOOLBAR_PROPS = {
    add: false,
    edit: false,
    delete: false,
    start: false,
    print: true,
    email: true
};

/**
 * Класс реализует документ справочника признаков.
 */
class Documents extends React.PureComponent {
    constructor(props) {
        super(props);
        this.renderer = this.renderer.bind(this);
        this.checkWeekEnds = this.checkWeekEnds.bind(this);
    }

    render() {
        return <DocumentRegister initData={this.props.initData}
                                 history={this.props.history ? this.props.history : null}
                                 module={this.props.module}
                                 ref='register'
                                 toolbarProps={TOOLBAR_PROPS}
                                 docTypeId={DOC_TYPE_ID}
                                 style={styles}
                                 render={this.renderer}
                                 trigger_select={this.checkWeekEnds}
                                 custom_styling={this.custom_styling}
        />;
    }

    renderer(self) {
        return null
    }

    /**
     * преобразует заголовок таблицы в части стиля
     * @param self
     */
    checkWeekEnds(self) {
        if (!self.gridConfig) {
            return null;
        }

        let weekEnds = [];
        if (self.gridData.length) {
            weekEnds = self.gridData[0].week_ends;
        }

        if (weekEnds.length) {
            self.gridConfig.map(column => {
                // проверяем есть ли выходной в этот день и задаем жирный цвет если есть
                column.showBold = weekEnds.indexOf(Number(column.name)) > -1 ? true: false;
                return column;
            });
        }

        // filter
        self.gridData = self.gridData.filter(row =>row.is_row)


    }

    /**
     * кастомное оьработка стиля для яцейки
     */
    custom_styling(column, row) {
        let style = {};
        if (!isNaN(column.name) && row.nom_id == 999999999 && row[column.id] !== null) {
            // посещвемлсть
            //В строке «Посещаемость» в полях отображаются суммарное количество посещений по группам и поля залиты соответственно: больше 0 – светло зеленым, 0 – светло красным цветом. Все поля с прочими услугами отображают суммарное значение из «Дневной формы учета ежедневных услуг», если их больше 0 или «Пусто» - если 0
            style = row[column.id] ? styles.custom.positive : styles.custom.negative;
        }
        return style;
    }

}


module.exports = (Documents);


