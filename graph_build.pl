#!/usr/bin/perl

use utf8::all;
use warnings;
use strict;
use Data::Dumper;
#use FL3 'pt';
use XML::LibXML;
#use Lingua::Jspell;

# Parse XML igual ao anterior
my $xml_src = $ARGV[0];

my $parser = XML::LibXML->new;
my $doc = $parser->parse_file($xml_src);
my @nodeList = $doc->getElementsByTagName('news');

my %grafo;
foreach my $news (@nodeList) 
{
	foreach my $tag ($news->childNodes()) 
	{
		my $tagname = $tag->nodeName();
		my $texto = "";

		if(!($tagname =~ "text")) 
		{
			# Retirar tags (excepto ENT) e retornar texto único
			$texto .= build_text($news->getElementsByTagName($tagname));
			$texto .= ". "; # Cada tag conta como nova frase

			# Entidades relacionadas numa notícia
			build_graph($texto);

			# Entidades relacionadas em cada frase
			my @frases = split(/\./,$texto);
			for my $frase (@frases)
			{
				build_graph($frase);
			}
		}
	}
}

#print Dumper(\%grafo);
print graph_as_XML();

sub graph_as_XML
{
	my $xml = "<?xml version=\"1.0\" encoding=\"UTF-8\"?>\n<graph>\n";

	for my $key (keys %grafo)
	{
		$xml .= "<node>\n";
		$xml .= "<entity>$key</entity>\n";
		$xml .= "<type>$grafo{$key}{'type'}</type>\n";

		$xml .= "<rels>\n";
		for my $rel (keys %{$grafo{$key}{'rels'}})
		{
			$xml .= "<rel>";
			$xml .= "<ent>$rel</ent>\n";
			$xml .= "<weight>$grafo{$key}{'rels'}{$rel}</weight>\n";
			$xml .= "</rel>\n";
		}
		$xml .= "</rels>\n";

		$xml .= "</node>\n";
	}

	$xml .= "</graph>\n";

	return $xml;
}

sub build_graph
{
	my $texto = shift;
	
	my $tipo = qr{PAIS|CIDADE|PESSOA|DATA};
	my @ents = ($texto =~ /<ENT id="[0-9]+" type="$tipo">[^<]*<\/ENT>/g);
	my $size = scalar @ents;

	for(my $i=0; $i<$size; $i++)
	{
		if($ents[$i] =~ /<ENT id="[0-9]+" type="([^"]*)">([^<]*)<\/ENT>/)
		{
			#id não é necessário
			my $type1 = $1;
			my $ent1 = $2;

			for(my $j=$i; $j<$size; $j++)
			{
				if($ents[$j] =~ /<ENT id="[0-9]+" type="([^"]*)">([^<]*)<\/ENT>/)
				{
					my $type2 = $1;
					my $ent2 = $2;

					if(! ($ent1 eq $ent2))
					{
						$grafo{$ent1}{'type'} = $type1;	
						$grafo{$ent1}{'rels'}{$ent2}++;
						
						$grafo{$ent2}{'type'} = $type2;	
						$grafo{$ent2}{'rels'}{$ent1}++;
					}
				}
			}
		}
	}
}

sub build_text
{
	my $texto = shift;
	my $res = "";

	foreach my $elem ($texto->childNodes()) 
	{
		if($elem->nodeName() =~ "text") 
		{
			$res .= "$elem ";
		}
		else
		{
			if($elem =~ /<ENT id="([0-9]+)" type="([^"]*)">([^<]*)<\/ENT>/)
			{
				my $id = $1;
				my $type = $2;
				my $ent = $3;

				$res .= "<ENT id=\"$id\" type=\"$type\">$ent</ENT> ";
			}
		}
	}

	return $res;
}


