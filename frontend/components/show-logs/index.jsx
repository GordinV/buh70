'use strict';

const PropTypes = require('prop-types');

const React = require('react'),
    styles = require('./styles'),
    DataGrid = require('../../components/data-grid/data-grid.jsx'),
    Button = require('./../../components/button-register/button-register.jsx'),
    ModalPage = require('./../../components/modalpage/modalPage.jsx');

const gridConfig = [
    {id: "kasutaja", name: "Kasutaja", width: "20%", show: true},
    {id: "koostatud", name: "Koostatud", width: "15%"},
    {id: "muudatud", name: "Muudatud", width: "15%"},
    {id: "prinditud", name: "Prinditud", width: "15%"},
    {id: "email", name: "Meilitud", width: "15%"},
    {id: "earve", name: "e-Arve", width: "15%"},
    {id: "kustutatud", name: "Kustutatud", width: "15%"}];

class ShowLogs extends React.PureComponent {
    constructor(props) {
        super(props);
        this.state = {
            show: !!this.props.data.length
        };

        this.modalPageClick = this.modalPageClick.bind(this);
    }

    render() {
        return (this.state.show ? this.modalPage() : (
                <Button
                    ref="btnLogs"
                    value='Loggid'
                    show={this.props.show}
                    onClick={(e) => this.handleClick(e)}>
                    <img ref='image' src={styles.button.icon}/>
                </Button>
            )

        )
    }

    handleClick() {
        this.props.onClick();
        this.setState({
            show: true
        });
    }

    modalPage() {
        let modalObjects = ['btnOk'];

        return (
            <ModalPage
                modalObjects={modalObjects}
                ref="modalpage-grid"
                show={true}
                modalPageBtnClick={this.modalPageClick}
                modalPageName='Loggid'>
                <div ref="grid-row-container">
                    <DataGrid gridData={this.props.data.data}
                              gridColumns={gridConfig}
                              showToolBar={false}
                              ref="data-grid"/>
                </div>
            </ModalPage>);
    }

    modalPageClick(event) {
        if (event === 'Ok') {

            // показать новое значение
            this.setState({show: false});
        }
    }

}

ShowLogs.propTypes = {
    show: PropTypes.bool
};

ShowLogs.defaultProps = {
    show: true
};

module.exports = ShowLogs;
