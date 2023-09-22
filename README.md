<h1 align="center">
<br> Robust Portfolio Optimization and Rebalancing with Transaction Cost: A Case Study in Brazil Stock Exchange
</h1>
Repository for the course on Optimization Methods in Finance at  <a href="https://www.cos.ufrj.br/" > PESC - Programa de Engenharia de Sistemas e Computação</a> from <a href="https://ufrj.br/" >UFRJ - Federal University of Rio de Janeiro</a>, taught by <a href="https://www.cos.ufrj.br/~pegonzalez/">Prof.  Pedro Henrique Gonzalez</a>.

Developed by Gabriel Souto and Ronald Albert.
<h2 align="center">
The project
</h2>
The project is implements a robust optimization method for portfolio selection considering the existence of transaction costs in portfolio rebalancing. 

It's entirely implemented in Julia, and all the results are available in the Julia notebook `results.ipynb`.

<h2 align="center">
File list
</h2>
<ul>
    <li><h3>src/src/Finance.jl</h3></li>
    <p>Module where the data structure for finance operations is defined, in such module finance data is retrieved from Yahoo Finance and metrics such as average stocks return and covariance matrix are estimated.</p>
    <li><h3>src/MarkowitzModel.jl</h3></li>
    <p>Module where the traditional Markowitz model is defined, with a function for portfolio optimization.</p>
    <li><h3>src/RobustMarkowitzModel.jl</h3></li>
    <p>Module where the robust version of the traditional Markowitz model is defined, with a function for portfolio optimization.</p>
</ul>
