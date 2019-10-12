'use strict';

const PropTypes = require('prop-types');
const React = require('react');

const
    DocumentTemplate = require('../../documentTemplate/index.jsx'),
    InputText = require('../../../components/input-text/input-text.jsx'),
    TextArea = require('../../../components/text-area/text-area.jsx'),
    DataGrid = require('../../../components/data-grid/data-grid.jsx'),
    ModalPage = require('../../../components/modalpage/modalPage.jsx'),
    styles = require('./styles');

class LapseGrupp extends React.PureComponent {
    constructor(props) {
        super(props);
        this.state = {
            loadedData: false,
            docId: props.docId ? props.docId : Number(props.match.params.docId),
            module: 'lapsed'
        };

        this.renderer = this.renderer.bind(this);
//        this.handleGridBtnClick = this.handleGridBtnClick.bind(this);
    }

    render() {
        let initData = this.props.initData ? this.props.initData : {};

        return <DocumentTemplate docId={this.state.docId}
                                 ref='document'
                                 module={this.state.module}
                                 docTypeId='LAPSE_GRUPP'
                                 userData={this.props.userData}
                                 initData={initData}
                                 renderer={this.renderer}
                                 handleGridBtnClick={this.handleGridBtnClick}
                                 history={this.props.history}
                                 focusElement={'input-kood'}
        />
    }

    /**
     *Вернет кастомные компоненты документа
     */

    renderer(self) {
        let bpm = self.docData && self.docData.bpm ? self.docData.bpm : [],
            isEditMode = self.state.edited;

        if ((self.docData.id == 0 || !self.docData.parentid) && this.state.lapsId) {
            //new record
            self.docData.parentid = this.state.lapsId;
        }

        return (
            <div style={styles.doc}>
                <div style={styles.docRow}>
                    <div style={styles.docColumn}>
                        <InputText title='Kood:'
                                   name='kood'
                                   value={self.docData.kood || ''}
                                   ref='input-kood'
                                   readOnly={!isEditMode}
                                   onChange={self.handleInputChange}/>

                        <InputText title='Nimetus:'
                                   name='nimetus'
                                   value={self.docData.nimetus || ''}
                                   ref='input-nimetus'
                                   readOnly={!isEditMode}
                                   onChange={self.handleInputChange}/>
                        <label>
                            All üksused
                            <InputText title=''
                                       name='all_yksus_1'
                                       value={self.docData.all_yksus_1 || ''}
                                       ref='input-all_yksus_1'
                                       readOnly={!isEditMode}
                                       onChange={self.handleInputChange}/>
                            <InputText title=''
                                       name='all_yksus_2'
                                       value={self.docData.all_yksus_2 || ''}
                                       ref='input-all_yksus_2'
                                       readOnly={!isEditMode}
                                       onChange={self.handleInputChange}/>
                            <InputText title=''
                                       name='all_yksus_3'
                                       value={self.docData.all_yksus_3 || ''}
                                       ref='input-all_yksus_3'
                                       readOnly={!isEditMode}
                                       onChange={self.handleInputChange}/>
                            <InputText title=''
                                       name='all_yksus_4'
                                       value={self.docData.all_yksus_4 || ''}
                                       ref='input-all_yksus_4'
                                       readOnly={!isEditMode}
                                       onChange={self.handleInputChange}/>
                            <InputText title=''
                                       name='all_yksus_5'
                                       value={self.docData.all_yksus_5 || ''}
                                       ref='input-all_yksus_5'
                                       readOnly={!isEditMode}
                                       onChange={self.handleInputChange}/>
                        </label>
                    </div>
                </div>
                <div style={styles.docRow}>
                    <TextArea title="Märkused"
                              name='muud'
                              ref="textarea-muud"
                              onChange={self.handleInputChange}
                              value={self.docData.muud || ''}
                              readOnly={!isEditMode}/>
                </div>
            </div>
        );
    }

    /*
    // обработчик события клик на гриде родителей
    handleGridBtnClick(btnName, activeRow, id, docTypeId) {
        switch (btnName) {
            case "edit":
                this.props.history.push(`/lapsed/${docTypeId}/${id}`);
                break;
            case "add":
                this.props.history.push(`/lapsed/${docTypeId}/0/${this.state.docId}`);
                break;
            case "delete":
                console.log('btnDelete clicked');
                break;
            default:
                console.log('Vigane click');
        }

    }
*/


}

LapseGrupp.propTypes = {
    docId: PropTypes.number,
    initData: PropTypes.object,
    userData: PropTypes.object,
};

LapseGrupp.defaultProps = {
    params: {docId: 0},
    initData: {},
    userData: {}
};


module.exports = (LapseGrupp);