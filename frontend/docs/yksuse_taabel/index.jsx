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

    }

}


module.exports = (Documents);


