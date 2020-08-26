'use strict';

const React = require('react');
const DocumentRegister = require('./../documents/documents.jsx');

const styles = require('./styles');
const DOC_TYPE_ID = 'PAEVA_TAABEL';
const getDefaultDates = require('./../../../libs/getDefaultDate');
const DocContext = require('./../../doc-context.js');


/**
 * Класс реализует документ справочника признаков.
 */
class Documents extends React.PureComponent {
    constructor(props) {
        super(props);
        this.state = {
            kogus: 0
        };
        this.renderer = this.renderer.bind(this);

// инициализация фильтра
        if (!DocContext.filter[DOC_TYPE_ID]) {
            let defaultDates = getDefaultDates();
            const filterData =
                [
                    {
                        name: "id",
                        type: "text",
                        value: null,
                    }, {
                    name: "kpv",
                    type: "date",
                    value: defaultDates.start,
                    start: defaultDates.start,
                    end: defaultDates.end
                },
                    {
                        name: "yksus",
                        type: "text",
                        value: null,
                    },
                    {
                        name: "staatus",
                        type: "text",
                        value: null
                    }
                ];
            DocContext.filter[DOC_TYPE_ID] = filterData;
        }

    }

    render() {
        return (
            <div>
                <DocumentRegister initData={this.props.initData}
                                  history={this.props.history ? this.props.history : null}
                                  module={this.props.module}
                                  ref='register'
                                  docTypeId={DOC_TYPE_ID}
                                  style={styles}
                                  render={this.renderer}/>
            </div>
        );

    }

// custom render
    renderer(self) {
        return null;
    }

}


module.exports = (Documents);


