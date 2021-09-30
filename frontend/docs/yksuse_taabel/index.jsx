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
        this.onClickHandler = this.onClickHandler.bind(this);

    }

    render() {
        return <DocumentRegister history={this.props.history ? this.props.history : null}
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
        return (<ToolbarContainer>
                <BtnGetXml
                    value={'Saama CSV fail'}
                    onClick={this.onClickHandler}
                    ref={`btn-getXml`}
                    showDate={false}
                />
            </ToolbarContainer>
        )
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
            style = Number(row[column.id]) ? styles.custom.positive : styles.custom.negative;
        }
        return style;
    }

    //handler для события клик на кнопках панели
    onClickHandler(event) {
        const Doc = this.refs['register'];

        if (Doc.gridData && Doc.gridData.length) {
            //делаем редайрект на конфигурацию
            let sqlWhere = Doc.state.sqlWhere;
            let url = `/reports/yksuse_taabel/${DocContext.userData.uuid}`;
            let params = encodeURIComponent(`${sqlWhere}`);
            let notEmptyFilter = Doc.filterData.filter(row => {
                return row.value;
            });
            let filter = encodeURIComponent(`${(JSON.stringify(notEmptyFilter))}`);


            let fullUrl = sqlWhere ? `${url}/${filter}/${params}`: `${url}/${filter}`;
            window.open(fullUrl);

        } else {
            Doc.setState({
                warning: 'Tulemus 0', // строка извещений
                warningType: 'notValid',

            });
        }
    }


}


module.exports = (Documents);


