<?xml version="1.0" encoding="UTF-8"?>
<xsl:stylesheet version="1.0" xmlns:xsl="http://www.w3.org/1999/XSL/Transform" xmlns:fn="http://www.w3.org/2005/xpath-functions" xmlns:exsl="http://exslt.org/common" xmlns:m8="http://m8data.com">
	<!--


	-->
	<xsl:template name="Head2">
		<script src="{$start/@prefix}p/formulyar/js/jquery.min-1.9.0.js"/>
		<script>var source = "";</script>
		<!-- по какой-то причине, если не втавить этот тэг, то предыдущий открывающий тег скрипта не закроется //
		<script src="{$start/@prefix}system/a/js/xalio.js"/>-->
		<script>var source2 = "";</script>
	</xsl:template>
	<xsl:template name="TitleAndMisk">
		<title>
			<xsl:value-of select="$start/@avatar"/>: административный раздел</title>
	</xsl:template>
	<!--	


	-->
	<xsl:template name="startBody">
		<xsl:call-template name="footer"/>
		<!--<div style="position: fixed; bottom: 5px; left: 5px; z-index: 1">
			<a href="{$start/@prefix}teplotn/m8/{substring($fact,1,1)}/{$fact}/{$author}/{$quest}">calculator</a>
			<xsl:text> | </xsl:text>
			<a href="{$start/@prefix}system/m8/{substring($fact,1,1)}/{$fact}/{$author}/{$quest}">sys</a>
			<xsl:text> | </xsl:text>
			<a href="{$start/@prefix}xalio/m8/{substring($fact,1,1)}/{$fact}/{$author}/{$quest}">refresh</a>
			<xsl:text> | </xsl:text>
			<a href="{$start/@prefix}m8/{substring($fact,1,1)}/{$fact}/{$author}/{$quest}/port.xml">xml</a>
		</div>
		<div style="position: fixed; bottom: 5px; right: 5px; color: gray; z-index: 1">
			<span title="аватар"><xsl:value-of select="$avatar"/></span>
			<xsl:text> |  </xsl:text>	
			<xsl:value-of select="$localtime"/>
			<xsl:if test="$user != 'guest' ">
				<xsl:text> |  </xsl:text>
				<xsl:value-of select="$user"/>
				<xsl:text> |  </xsl:text>
				<a href="{$start/@prefix}m8/?logout=true" style="color: red">выйти</a>
			</xsl:if>
		</div>-->
		<xsl:apply-templates select="." mode="start"/>
	</xsl:template>
	<!--

	-->
	<xsl:template match="port|terminal" mode="start">
		<xsl:choose>
			<xsl:when test=" $fact = 'n' ">
				<br/>
				<br/>
				<br/>
			</xsl:when>
			<xsl:otherwise>
				<div>
					<xsl:choose>
						<xsl:when test="m8:index( $fact )/role">
							<xsl:message terminate="no">Зеленая карта</xsl:message>
							<div style="background: #EFD; padding: 1em">
								<xsl:message> ^ ^ ^ ^ ^ - Зона ссылок наверх - ^ ^ ^ ^ ^ </xsl:message>
								<table style="font-size: 1em;" width="100%">
									<tr>
										<td width="30%" valign="top">
											<xsl:for-each select="exsl:node-set($parent)/*">
												<xsl:if test="position()!=1">
													<xsl:text> / </xsl:text>
												</xsl:if>
												<xsl:variable name="preceding-sibling" select="name( preceding-sibling::*[1] )"/>
												<a href="{m8:root( name() )}" style="{m8:color( name() )}" title="{m8:holder( name() )}">
													<xsl:apply-templates select="." mode="simpleName"/>
												</a>
											</xsl:for-each>
										</td>
										<td width="40%" align="center" style="color: #444" valign="top">
											<div style="padding-bottom: .4em">
												<span style="font-size: 1.3em; {m8:color( $fact )}" title="{m8:holder( $fact )}">
													<xsl:choose>
														<xsl:when test="m8:port( $fact )/i[not(r)]">
															<xsl:apply-templates select="m8:port( $fact )/i/*" mode="simpleName"/>&#160;<sup style="font-size: .5em; color: #777" title="{$fact}">
																<xsl:value-of select="substring-before( substring-after( $fact, '-' ), '-' )"/>
															</sup>
														</xsl:when>
														<xsl:otherwise>
															<xsl:text>нечто </xsl:text>
															<xsl:value-of select="$fact"/>
														</xsl:otherwise>
													</xsl:choose>
												</span>
											</div>
											<xsl:if test="$parentName != $typeName">
												<!-- and $parentName != 'n'-->
												<xsl:text>  c типом </xsl:text>
												<a href="{m8:root( $typeName )}" style="{m8:color( $typeName)}" title="{m8:holder( $typeName )}">
													<b>
														<xsl:apply-templates select="exsl:node-set($parent)/*[last()]/*" mode="simpleName"/>
													</b>
												</a>
												<!--<xsl:text>  в квесте </xsl:text>
												<a href="{$start/@prefix}a/{$ctrl}/{m8:dir( $quest )}" style="{m8:color( $quest)}" title="{m8:holder( $quest )}">
													<xsl:apply-templates select="@quest" mode="simpleName"/>
												</a>-->
											</xsl:if>
											<xsl:if test="$modifier != 'n'">
												<span> в модификации </span>
												<a href="{m8:root( $modifier )}" style="{m8:color( $modifier )}" title="{m8:holder( $modifier )}">
													<b>
														<xsl:apply-templates select="$start/@modifier" mode="simpleName"/>
													</b>
												</a>
											</xsl:if>
										</td>
										<!-- n500 r i n n500 -->
										<td width="30%" align="right" valign="top">
											<xsl:variable name="siblings">
												<xsl:for-each select="m8:index( $director )/director/*">
													<xsl:sort select="m8:title( name() )"/>
													<xsl:copy/>
												</xsl:for-each>
											</xsl:variable>
											<!--<div>typeName: <xsl:value-of select="$typeName"/></div>
													<xsl:apply-templates select="exsl:node-set($siblings)/*" mode="serialize"/>-->
											<table style="font-size: .9em">
												<tr>
													<td align="right">
														<xsl:if test="exsl:node-set($siblings)/*[name()=$fact]/preceding-sibling::*">
															<xsl:variable name="predName" select="name(exsl:node-set($siblings)/*[name()=$fact]/preceding-sibling::*[1])"/>
															<a href="{m8:action( $predName, $modifier )}" style="{m8:color( $predName )}" title="{m8:holder( $predName )}">
																<xsl:apply-templates select="exsl:node-set($siblings)/*[name()=$fact]/preceding-sibling::*[1]" mode="simpleName"/>
															</a>
														</xsl:if>
													</td>
													<td>&#160;&#11012;&#160;</td>
													<!-- &#9668;&#160;&#160;&#9658;-->
													<td>
														<xsl:if test="exsl:node-set($siblings)/*[name()=$fact]/following-sibling::*">
															<xsl:variable name="nextName" select="name(exsl:node-set($siblings)/*[name()=$fact]/following-sibling::*[1])"/>
															<a href="{m8:action( $nextName, $modifier )}" style="{m8:color( $nextName )}" title="{m8:holder( $nextName )}">
																<xsl:apply-templates select="exsl:node-set($siblings)/*[name()=$fact]/following-sibling::*[1]" mode="simpleName"/>
															</a>
														</xsl:if>
													</td>
												</tr>
											</table>
										</td>
									</tr>
								</table>
								<xsl:message> ^ ^ ^ ^ ^ - Зона ссылок наверх (END) - ^ ^ ^ ^ ^ </xsl:message>
								<br/>
								<xsl:call-template name="quest_port"/>
								<br style="clear: both"/>
							</div>
						</xsl:when>
						<xsl:otherwise>
							<xsl:message>Красная карта</xsl:message>
							<div style="margin: 2em; padding: 1em; background: #FED">
								<div style="float: right">
									<a href="{$start/@prefix}a/{$ctrl}/">X</a>
								</div>
								<br style="clear: both"/>
							</div>
						</xsl:otherwise>
					</xsl:choose>
				</div>
			</xsl:otherwise>
		</xsl:choose>
		<xsl:if test="( m8:index( $fact )/object/*[m8:director( name() ) = $fact] or m8:index( $fact )/director/*[name()!='n'][m8:leader( name() )!=$fact] ) and $modifier = 'n'">
			<div style="padding: 3em" id="linkDownZone">
				<xsl:message> v v v v v - Зона ссылок вниз - v v v v v </xsl:message>
				<table width="100%" style="font-size: .9em;">
					<tr>
						<td align="center" valign="top" width="40%">
							<xsl:if test="m8:index( $fact )/object/*[m8:director( name() ) = $fact]">
								<b>Экземпляры</b>
								<div style="padding: 1em">
									<xsl:for-each select="m8:index( $fact )/object/*[m8:director( name() ) = $fact]">
										<xsl:sort select="m8:title( name() )"/>
										
										<div style="font-size: 1.4em; padding: .1em">
											<a href="{ m8:root( name() )}" style="{m8:color( name() )}" title="{m8:holder( name() )}">
												<xsl:apply-templates select="." mode="simpleName"/>
											</a>
											<xsl:choose>
												<xsl:when test="1200 > $time - m8:path( name(), 'subject_r' )/*/@time">
													<xsl:text> </xsl:text>
													<sup style="color: red">new</sup>
												</xsl:when>
												<xsl:when test="120 > $time - m8:role1( name() )/*/@time">
													<xsl:text> </xsl:text>
													<sup style="color: magenta">change</sup>
												</xsl:when>
											</xsl:choose>
											<xsl:if test="m8:holder( name() )=$user"><!-- and $fact != 'n'-->
												<xsl:text> </xsl:text>
												<sup>
													<a href="{ m8:root( $fact ) }?a0={ m8:path( name(), 'subject_r' )/*/@triple }" style="color: #bbb" onclick="return confirm('Удаление факта &#171;{m8:title( name() )}&#187;')" title="удалить">del</a>
												</sup>
											</xsl:if>
											<xsl:if test="m8:port( name() )/*[name()!='r']">
												<xsl:text> </xsl:text>
												<sup>
													<a href="{ m8:root( $fact ) }?a={ m8:path( name(), 'subject_r' )/*/@triple }" style="color: green" title="копировать">
														<xsl:attribute name="href"><xsl:value-of select="concat( m8:root( $fact ), '?a=' )"/>
															<xsl:for-each select="m8:port( name() )/*[name()!='r']">
															<xsl:variable name="sentN" select="translate( position(), '123456789', 'bcdefghkl' )"/>
															<xsl:value-of select="concat( '&amp;', $sentN, '2=', name(),   '&amp;', $sentN, '3=', name(*) )"/>
														</xsl:for-each></xsl:attribute>
														<xsl:text>к</xsl:text>
													</a>
												</sup>
											</xsl:if>
										</div>
									</xsl:for-each>
								</div>
							</xsl:if>
							<xsl:if test="m8:index( $fact )/director/*[name()!='n'][m8:leader( name() )!=$fact]">
								<b style="color: #555">Состав</b>
								<div style="padding: 1em">
									<xsl:for-each select="m8:index( $fact )/director/*[name()!='n'][m8:leader( name() )!=$fact]">
										<xsl:sort select="m8:title( name() )"/>
										<div style="padding: .2em">
											<a href="{ m8:root( name() )}" style="{m8:color( name() )}" title="{m8:holder( name() )}">
												<xsl:apply-templates select="m8:port( name() )/r/*" mode="simpleName"/>
												<xsl:text> :: </xsl:text>
												<xsl:apply-templates select="." mode="simpleName"/>
											</a>
										</div>
									</xsl:for-each>
								</div>
							</xsl:if>
						</td>
					</tr>
				</table>
				<xsl:message> v v v v v - Зона ссылок вниз (END) - v v v v v </xsl:message>
			</div>
		</xsl:if>
		<div style="color: #777; padding: 4em">
			<xsl:message>= = = = = = = - Зона упоминаний - = = = = = =</xsl:message>
			<xsl:if test="m8:quest( $fact )/*[name()!=$fact] and $fact!='n' ">
				<br/>
				<div>
					<b>модификатор для</b>
					<div style="padding: .2em">
						<xsl:for-each select="m8:quest( $fact )/*[name()!=$fact]">
							<xsl:sort select="m8:title( name() )"/>
							<!--="@time-->
							<div>
								<xsl:choose>
									<xsl:when test="m8:index( name() )/subject">
										<a href="{m8:action( name(), $fact )}" style="{ m8:color( name() )}" title="{ m8:holder( name() ) }">
											<xsl:apply-templates select="m8:port( name() )/r/*" mode="simpleName"/> :: <xsl:apply-templates select="." mode="simpleName"/>
										</a>
									</xsl:when>
									<xsl:otherwise>
										<xsl:apply-templates select="." mode="simpleName"/>
									</xsl:otherwise>
								</xsl:choose>
							</div>
						</xsl:for-each>
					</div>
				</div>
			</xsl:if>
			<xsl:if test="m8:role1( $fact )/*[name()!='n'] and $fact!='n' and $modifier = 'n' ">
				<br/>
				<div>
					<b>модификация из</b>
					<div style="padding: .2em">
						<xsl:for-each select="m8:role1( $fact )/*[name()!='n']">
							<xsl:sort select="m8:title( name() )"/>
							<div>
								<a href="{m8:action( $fact, name() )}" style="{ m8:color( name() )}" title="{ m8:holder( name() ) }">
									<xsl:apply-templates select="m8:port( name() )/r/*" mode="simpleName"/> :: <xsl:apply-templates select="." mode="simpleName"/>
								</a>
							</div>
						</xsl:for-each>
					</div>
				</div>
			</xsl:if>
			<xsl:if test="m8:path( $fact, 'n', 'terminal' )/*[not(r)][name()!=$director] and $modifier = 'n' ">
				<br/>
				<div>
					<b>
						<a href="/{m8:dir( $fact, 'n' )}/terminal.xml" style="color: gray">упоминания</a>
					</b>
					<div style="padding: .2em">
						<xsl:for-each select="m8:path( $fact, 'n', 'terminal' )/*[not(r)][name()!=$director]">
							<xsl:sort select="m8:title( name() )"/>
							<div>
								<a href="{m8:root( name() )}" style="{ m8:color( name() )}" title="{ m8:holder( name() ) }">
									<xsl:apply-templates select="m8:port( name() )/r/*" mode="simpleName"/> :: <xsl:apply-templates select="." mode="simpleName"/>
								</a>
							</div>
						</xsl:for-each>
					</div>
				</div>
			</xsl:if>
			<xsl:message>= = = = = = = - Зона упоминаний (END) - = = = = = =</xsl:message>
		</div>
		<xsl:message> 
									@@@@@ - Зона генерации нового - @@@@@
				</xsl:message>
		<!--<div style="position: fixed; bottom: 50px; left: 50px; font-size: 2em; background-color: green; opacity: 0.5; padding: 1em; padding-bottom: 0; border-radius: 2em; ">
			<form action="{$start/@prefix}a/{$ctrl}/{m8:dir( $fact )}/">
				<span style="font-size: 11pt; color: white">Добавить: </span>
				<input type="hidden" name="quest" value="{$fact}"/>
				<select name="a" onchange="this.form.submit()">
					<option/>
					<xsl:for-each select="m8:path( 'r', 'predicate_n' )/*/*">
						<option value="{name()}">
							<xsl:apply-templates select="." mode="titleWord"/>
						</option>
					</xsl:for-each>
				</select>
			</form>
		</div>-->
		<style version="text/css">
			#circle {
			position: fixed; 
	width: 64px;
	height: 64px;
	-moz-border-radius: 32px;
	-webkit-border-radius: 32px;
	border-radius: 32px;
	#border: 4px solid gray;
	opacity: 0.6;
	font-size: 2.4em;
	line-height: 186%;
	background: green;
}
#circle a {color: yellow; }
		</style>
		<a href="{m8:root( $fact )}?a=" title="создать новый объект" style="color: white;">
			<span style="bottom: 64px; right: 64px; " id="circle">+</span>
		</a>
		<!--<div style="bottom: 70px; right: 165px; " id="circle">
			<a href="{$start/@prefix}a/{$ctrl}/{m8:dir( $fact )}/?a=" title="реплицировать внутрь" style="color: purple">&#9632;</a>
		</div>
		<div style="bottom: 70px; right: 70px; font-size: 4.7em; line-height: 64%;" id="circle">
			<a href="{$start/@prefix}a/{$ctrl}/?a=" title="реплицировать на свободу" style="color: red">&#9679;</a>
		</div>-->
		<xsl:message> newQuestName
			@@@@@ - Зона генерации нового (END) - @@@@@
		</xsl:message>
	</xsl:template>
	<!--


	-->
	<xsl:template name="quest_port">
		<xsl:variable name="predicatesThisNechto">
			<xsl:for-each select="m8:index( $startTypeName )/object/*">
				<xsl:variable name="subjectName" select="name()"/>
				<xsl:for-each select="m8:path( $startTypeName, concat( 'object_', $subjectName ) )/*">
					<xsl:for-each select="m8:port( $subjectName, name() )/*[name() != 'r' ]">
						<xsl:element name="{name()}">_</xsl:element>
					</xsl:for-each>
				</xsl:for-each>
			</xsl:for-each>
		</xsl:variable>
		<xsl:variable name="sorted_predicates">
			<xsl:for-each select="exsl:node-set($predicatesThisNechto)/*">
				<xsl:sort select="m8:title( name() )"/>
				<!--<xsl:sort select="name()"/>-->
				<xsl:copy-of select="."/>
			</xsl:for-each>
		</xsl:variable>
		<xsl:variable name="final_sort">
			<xsl:apply-templates select="exsl:node-set($sorted_predicates)/*[1]" mode="predicate_grouping_new"/>
		</xsl:variable>
		<xsl:variable name="fact_n" select="m8:value( name( $factPort/n/* ) )"/>
		<xsl:if test="$fact_n/*[name()='svg']">
			<style type="text/css">
				.svg_formulyar svg {
					background-color: white;
					max-width: 350px !important;
					max-height: 200px !important;
				}
			</style>
			<div class="svg_formulyar" style="float: left">
				<xsl:copy-of select="$fact_n/*"/>
			</div>
		</xsl:if>
		<table width="92%" style="font-size: 1em">
			<tr>
				<td align="center" valign="top">
					<xsl:message>!! Левая панель: значения порта !!</xsl:message>
					<div style="padding: 1em; margin: .5em">
						<!--<xsl:choose>
							<xsl:when test="$startIndex/*[name()!='subject']">-->
						<table>
							<xsl:for-each select="$startPort/*[name()!='r']">
								<xsl:sort select="name()"/>
								<xsl:variable name="pName" select="name()"/>
								<tr>
									<th valign="top" align="right">
										<a href="{ m8:root( $pName )}">
											<span style="font-size: .8em; color: black">
												<xsl:choose>
													<xsl:when test="$pName = 'i' ">имя</xsl:when>
													<xsl:when test="$pName = 'n' ">файл</xsl:when>
													<xsl:when test="$pName = 'd' ">связь</xsl:when>
													<xsl:when test="$pName=$fact">по умолчанию</xsl:when>
													<xsl:otherwise>
														<xsl:apply-templates select="." mode="simpleName"/>
													</xsl:otherwise>
												</xsl:choose>
											</span>
										</a>
									</th>
									<td valign="top" align="left">
										<!--<xsl:for-each select="*">-->
										<table>
											<tr>
												<td>
													<xsl:if test="$pName != 'd' or $modifier='n'">
														<xsl:call-template name="editParamOfPort">
															<xsl:with-param name="predicateName" select="$pName"/>
															<xsl:with-param name="objectElement" select="$startPort"/>
														</xsl:call-template>
													</xsl:if>
												</td>
												<td valign="top">
													<xsl:choose>
														<xsl:when test="$modifier='n'">
															<a href="{m8:root( name(*) )}">q</a>
														</xsl:when>
														<xsl:when test="m8:port($modifier, $fact)/d">
															<xsl:value-of select="$symbol_replace"/>
														</xsl:when>
														<xsl:otherwise>
															<a href="{m8:action( $modifier, $fact )}&amp;d=0">
																<xsl:value-of select="$symbol_replace"/>
															</a>
														</xsl:otherwise>
													</xsl:choose>
												</td>
												<!--<xsl:if test="name()!='n'">-->
												<td valign="top">
													<!--<a href="{$startID}/?a0={name(*/*)}">x</a>-->
													<a href="{m8:action( $fact, $modifier )}&amp;a0={name(*/*)}">
														<xsl:value-of select="$symbol_del"/>
													</a>
												</td>
												<!--</xsl:if>-->
												<td valign="top">
													<xsl:if test="$adminMode">
														<sup>
															<a href="/{m8:dir( name(*) )}/value.xml" style="color:gray; font-size:.6em">
																<xsl:value-of select="name(*)"/>
															</a>
														</sup>
													</xsl:if>
												</td>
											</tr>
										</table>
										<!--</xsl:for-each>-->
									</td>
								</tr>
							</xsl:for-each>
						</table>
						<xsl:variable name="holder" select="m8:holder( $fact )"/>
						<!--<div style="position: absolute; left:0; bottom: 4em">-->
						<div style="background: #ded; padding: .5em; opacity: 0.75; position: fixed; left:0; bottom: 4em">
							<xsl:message>				-- Вывод пульта навигации --</xsl:message>
							<xsl:variable name="newQuestName">
								<xsl:choose>
									<xsl:when test="exsl:node-set($parent)/*[last()-1]">
										<xsl:value-of select="name( exsl:node-set($parent)/*[last()-1] )"/>
									</xsl:when>
									<xsl:otherwise>n</xsl:otherwise>
								</xsl:choose>
							</xsl:variable>
							<table cellpadding="0">
								<tr>
									<td valign="middle">
										<span style="font-size: .8em; color: brown">модификация</span>
									</td>
									<td valign="middle">
										<form action="{m8:root( $fact )}" id="editParamOfPort" style="margin: .5em">
											<select name="modifier" onchange="this.form.submit()">
												<option/>
												<xsl:for-each select="m8:index( $modifier )/director/*[name()!=$fact]">
													<xsl:sort select="m8:title( name() )"/>
													<option value="{name()}">
														<!--<xsl:if test="name() = $modifier">
																	<xsl:attribute name="selected">selected</xsl:attribute>
																</xsl:if>-->
														<xsl:apply-templates select="." mode="simpleName"/>
													</option>
												</xsl:for-each>
											</select>
										</form>
									</td>
									<xsl:if test="$modifier != 'n' ">
										<td valign="middle">
											<xsl:text>&#160;</xsl:text>
											<a href="{m8:action( $fact, m8:director( $modifier ) )}" title="to new Quest - { $newQuestName }">
												<xsl:value-of select="$symbol_up"/>
											</a>
										</td>
										<td valign="middle">
											<xsl:text>&#160;</xsl:text>
											<a href="{m8:action( $fact )}" title="удаление">
												<xsl:value-of select="$symbol_del"/>
											</a>
										</td>
									</xsl:if>
								</tr>
								<!--	</table>
									<table cellpadding="0">-->
								<!--<tr>
											<td valign="top">
												<span style="font-size: .8em; color: black">составление</span>
											</td>
											<td valign="top">
												<xsl:call-template name="editParamOfPort">
													<xsl:with-param name="predicateName" select="'modifier'"/>
													<xsl:with-param name="objectElement" select="m8:port( $director )"/>
													<xsl:with-param name="sourceValue">
														<option/>
														<xsl:copy-of select="m8:path( $director, 'index' )/object/*"/>
													</xsl:with-param> 
													<xsl:with-param name="action" select="m8:root( $fact )"/>
													<xsl:with-param name="hidden">
														<r>
															<xsl:value-of select="$typeName"/>
														</r>
													</xsl:with-param>
												</xsl:call-template>
											</td>
											<td valign="top">
												<a href="{m8:root( $fact )}/?r={$typeName}&amp;modifier={ $newQuestName }" title="to new Quest - { $newQuestName }">^</a>
											</td>
										</tr>-->
								<xsl:choose>
									<xsl:when test="$holder = $user">
										<tr>
											<td valign="middle">
												<span style="font-size: .8em; color: black">перемещение</span>
											</td>
											<td valign="middle">
												<form action="{m8:root( $fact )}" id="editParamOfPort" style="margin: .5em">
													<input type="hidden" name="r" value="n"/>
													<select name="modifier" onchange="this.form.submit()">
														<option/>
														<xsl:for-each select="m8:index( $director )/director/*[name()!=$fact and name()!='n']" xml:lang="n фильтровать, т.к. он почему-то есть в индексе самого n">
															<xsl:sort select="m8:title( name() )"/>
															<option value="{name()}">
																<!--<xsl:if test="name() = $modifier">
																	<xsl:attribute name="selected">selected</xsl:attribute>
																</xsl:if>-->
																<xsl:apply-templates select="." mode="simpleName"/>
															</option>
														</xsl:for-each>
													</select>
												</form>
												<!--<xsl:call-template name="editParamOfPort">
													<xsl:with-param name="predicateName" select="'modifier'"/>
													<xsl:with-param name="objectElement" select="m8:port( m8:director( $typeName ) )"/>
													<xsl:with-param name="sourceValue">
														<option/>
														<xsl:copy-of select="m8:index( $director )/object/*[name()!=$fact]"/>
													</xsl:with-param>
													<xsl:with-param name="hidden">
														<r>
															<xsl:value-of select="$typeName"/>
														</r>
														<xsl:if test="$director = $typeName">
															<object>
																<xsl:value-of select="$newQuestName"/>
															</object>
														</xsl:if>
													</xsl:with-param>
												</xsl:call-template>-->
											</td>
											<td valign="middle">
												<xsl:if test="$director != 'n' ">
													<xsl:text>&#160;</xsl:text>
													<a title="to new Quest - { $newQuestName } COMMON">
														<xsl:attribute name="href"><xsl:value-of select="concat( m8:action( $fact, $newQuestName ), '&amp;r=', $newQuestName )"/><!--<xsl:if test="$director = $typeName"><xsl:text>&amp;object=</xsl:text><xsl:value-of select="$newQuestName"/></xsl:if>--></xsl:attribute>
														<xsl:value-of select="$symbol_up"/>
													</a>
												</xsl:if>
											</td>
											<td valign="middle">
												<xsl:text>&#160;</xsl:text>
												<xsl:choose>
													<xsl:when test="$leader = $director">
														<a href="{m8:root( $director )}?a0={m8:triple( $fact )}" title="удаление" onclick="return confirm('Удаление факта &#171;{m8:title($fact)}&#187;')">
															<xsl:value-of select="$symbol_del"/>
														</a>
													</xsl:when>
													<xsl:otherwise>
														<a href="{m8:action( $fact, $director )}&amp;r={$director}" title="сделать тип таким же">
															<xsl:value-of select="$symbol_replace"/>
														</a>
													</xsl:otherwise>
												</xsl:choose>
											</td>
										</tr>
										<!--<tr>
											<td valign="top">
												<span style="font-size: .8em; color: black">разъединение</span>
											</td>
											<td valign="top">
												<xsl:call-template name="editParamOfPort">
													<xsl:with-param name="predicateName" select="'r'"/>
													<xsl:with-param name="objectElement" select="m8:port( m8:director( $typeName ) )"/>
													<xsl:with-param name="sourceValue">
														<option/>
														<xsl:copy-of select="m8:path( $leader, 'index' )/object/*[name()!=$fact]"/>
													</xsl:with-param>
													<xsl:with-param name="modifierName" select="$director"/>
												</xsl:call-template>
											</td>
											<xsl:variable name="typePosition" select="count( exsl:node-set($parent)/*[name(*)=$typeName][position()=1]/preceding-sibling::* )"/>
											<xsl:variable name="newTypeName">
												<xsl:choose>
													<xsl:when test="$typePosition">
														<xsl:value-of select="name( exsl:node-set($parent)/*[$typePosition]/* )"/>
													</xsl:when>
													<xsl:otherwise>n</xsl:otherwise>
												</xsl:choose>
											</xsl:variable>
											<td valign="top">
												<xsl:text>&#160;</xsl:text>
												<xsl:if test="$leader != 'n' ">
													<a href="{m8:action( $fact, $director )}&amp;r={$newTypeName}" title="to new typePosition - {$typePosition} / newTypeName - { $newTypeName }">
														<xsl:value-of select="$symbol_up"/>
													</a>
												</xsl:if>
											</td>
											<td valign="top">
												<xsl:text>&#160;</xsl:text>
												<xsl:if test="$leader != $director">
													<a href="{m8:action( $fact, $director )}&amp;r={$director}" title="удаление разъединения">
														<xsl:value-of select="$symbol_del"/>
													</a>
												</xsl:if>
											</td>
										</tr>-->
									</xsl:when>
									<xsl:otherwise>
										<tr>
											<td colspan="2">Владелец - <span style="{m8:fact_color( $holder )}">
													<xsl:value-of select="$holder"/>
												</span>
											</td>
										</tr>
									</xsl:otherwise>
								</xsl:choose>
							</table>
							<xsl:message>				-- Вывод пульта навигации (END) --
											</xsl:message>
							<!--<a href="{m8:root($parentName)}/?a0={name($parentPort/r/*/*)}&amp;a4={$parentName}" style="color: #222">удаление</a>-->
						</div>
					</div>
				</td>
				<td align="center" valign="top">
					<xsl:if test=" m8:holder( $fact )=$user or m8:holder( $modifier )=$user ">
						<!--not($modifier) or -->
						<div style="padding: 1em; ">
							<xsl:message>!! Правая панель: подсказки значений !!</xsl:message>
							<div>Добавление свойства:</div>
							<table cellpadding="3px">
								<xsl:for-each select="exsl:node-set($final_sort)/*[name()!='n' and name()!='d' and name()!='i' ]">
									<xsl:sort select="m8:title( name() )"/>
									<tr>
										<xsl:variable name="predicate" select="name()"/>
										<td valign="top" align="center">
											<a href="{m8:action( $fact )}&amp;{$predicate}=" title="популярность: {@count}">
												<xsl:attribute name="style"><xsl:if test="@count=1"><xsl:text>font-size: .8em</xsl:text></xsl:if></xsl:attribute>
												<xsl:apply-templates select="." mode="simpleName"/>
											</a>
										</td>
									</tr>
								</xsl:for-each>
							</table>
							<xsl:if test="m8:d( $fact )/div and $modifier != 'n' and not( starts-with( m8:d( $fact )/div[2]/span, 'xsd:' ) )">
								<!-- and not( start-with( m8:d( $fact )/div[2]/span, 'xsd:' ) )-->
								<div>------------------------</div>
								<xsl:for-each select="m8:d( $fact )/div">
									<div style="padding-bottom: .5em">
										<a href="{m8:action( $fact, $modifier )}&amp;{span[1]}=">
											<xsl:value-of select="m8:title( $types/@*[name()=current()/span[1]] )"/>
											<xsl:value-of select="concat( ' (', span[3], ')' )"/>
											<!--$types/@*[name()=span[1]]  <xsl:value-of select="m8:title( $types/@*[name()=span[1]] )"/>-->
										</a>
									</div>
								</xsl:for-each>
							</xsl:if>
							<div>------------------------</div>
							<!--<xsl:if test="not( $startPort/r )"></xsl:if>-->
							<!--<div style="padding-bottom: .2em">
								<a href="{m8:action( $fact, $modifier )}&amp;r=">связь</a>
							</div>-->
							<xsl:if test="$modifier != 'n' ">
								<div style="padding-bottom: .5em">
									<a href="{m8:action( $fact, $modifier )}&amp;sort=">сортировка</a>
								</div>
							</xsl:if>
							<xsl:if test="not( $startPort/i )">
								<div style="padding-bottom: .5em">
									<a href="{m8:action( $fact, $modifier )}&amp;i=">имя</a>
								</div>
							</xsl:if>
							<xsl:if test="not( $startPort/d )">
								<div style="padding-bottom: .5em">
									<a href="{m8:action( $fact, $modifier )}&amp;d=">связь</a>
								</div>
							</xsl:if>
							<xsl:if test="not( $startPort/n ) and $modifier = 'n'">
								<div style="padding-bottom: .5em">
									<a href="{m8:action( $fact, $modifier )}&amp;n=">структура</a>
								</div>
							</xsl:if>
							<xsl:message>
							START PORT:
							<xsl:apply-templates select="$startPort" mode="serialize"/>
							</xsl:message>
							<form action="{m8:root( $fact )}">
								<!--<input type="hidden" name="a1" value="{$fact}"/>-->
								<!--<input type="hidden" name="a4" value="n"/>-->
								<input type="hidden" name="modifier" value="{$modifier}"/>
								<input type="hidden" name="a3" value="r"/>
								<select name="a2" onchange="this.form.submit()">
									<option/>
									<!--<xsl:if test="not($startPort[name()='i'])">
									<option value="i">имя</option>
								</xsl:if>
								<xsl:if test="not($startPort[name()='d'])">
									<option value="d">описание</option>
								</xsl:if>
								<xsl:if test="not($startPort[name()='n'])">
									<option value="n">структура</option>
								</xsl:if>-->
									<xsl:if test="not( $factPort/*[name()=$fact] )">
										<option value="{$fact}">начало</option>
									</xsl:if>
									<xsl:for-each select="$types/@*">
										<xsl:sort select="m8:title( . )"/>
										<!--<xsl:variable name="typeName">
										<xsl:value-of select="name( m8:path( name(), $avatar, 'terminal' )/* )"/>
									</xsl:variable>-->
										<xsl:if test="not( $startPort/*[name()=current()] )">
											<option value="{.}">
												<xsl:apply-templates select="." mode="simpleName"/>
											</option>
										</xsl:if>
									</xsl:for-each>
								</select>
							</form>
						</div>
					</xsl:if>
				</td>
			</tr>
		</table>
		<!-- -->
	</xsl:template>
	<!--

	-->
	<xsl:template match="*" mode="predicate_grouping_new">
		<xsl:variable name="predicate" select="name()"/>
		<xsl:variable name="ref_with_this_predicate" select="../*[name() = $predicate]"/>
		<xsl:element name="{$predicate}">
			<xsl:attribute name="count"><xsl:value-of select="count($ref_with_this_predicate)"/></xsl:attribute>
			<xsl:text>_</xsl:text>
		</xsl:element>
		<xsl:apply-templates select="$ref_with_this_predicate[last()]/following-sibling::*[1]" mode="predicate_grouping_new"/>
	</xsl:template>
	<!--

	-->
	<xsl:template match="*" mode="predicate_grouping">
		<xsl:variable name="predicate" select="name()"/>
		<xsl:variable name="ref_with_this_predicate" select="../*[name() = $predicate]"/>
		<xsl:variable name="summ_sovp" select="../*[name() = $predicate]"/>
		<xsl:element name="{$predicate}">
			<xsl:attribute name="count"><xsl:value-of select="count($ref_with_this_predicate)"/></xsl:attribute>
			<xsl:for-each select="$ref_with_this_predicate">
				<xsl:for-each select="*">
					<xsl:sort select="name()"/>
					<xsl:element name="{name()}">
						<xsl:attribute name="sovpadenie"><xsl:value-of select="@sovpadenie"/></xsl:attribute>
					</xsl:element>
				</xsl:for-each>
			</xsl:for-each>
		</xsl:element>
		<!--
    Входящий список в $sorted_plain отсортирован,
    поэтому в следующую группу отправляем элемент,
    идущий за последним элементом в текущей группе
    -->
		<xsl:apply-templates select="$ref_with_this_predicate[last()]/following-sibling::*[1]" mode="predicate_grouping"/>
	</xsl:template>
	<!--

	-->
	<xsl:template match="*" mode="value_grouping">
		<xsl:variable name="value" select="name()"/>
		<xsl:variable name="ref_with_this_value" select="../*[name() = $value]"/>
		<xsl:variable name="ref_with_this_value_sum_sovp" select="sum(../*[name() = $value]/@sovpadenie)"/>
		<xsl:element name="{$value}">
			<xsl:attribute name="count"><xsl:value-of select="count($ref_with_this_value)"/></xsl:attribute>
			<xsl:attribute name="sovpadenie"><xsl:value-of select="$ref_with_this_value_sum_sovp"/></xsl:attribute>
		</xsl:element>
		<xsl:apply-templates select="$ref_with_this_value[last()]/following-sibling::*[1]" mode="value_grouping"/>
	</xsl:template>
	<!--

	-->
</xsl:stylesheet>
