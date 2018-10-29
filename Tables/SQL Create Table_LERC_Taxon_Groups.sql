USE NBNData
GO

/*---------------------------------------------------------------------------*\
	Create LERC_Taxon_Groups table
\*---------------------------------------------------------------------------*/
IF  EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[dbo].[LERC_Taxon_Groups]') AND type in (N'U'))
DROP TABLE [dbo].[LERC_Taxon_Groups]
GO

CREATE TABLE [dbo].[LERC_Taxon_Groups](
	[Taxon_Group_Name] [varchar](50) NOT NULL,
	[TaxonGroup] [varchar](60) NOT NULL,
	[DefaultCommonName] [varchar](100) NULL,
	[ReportGroupName] [varchar](100) NULL,
	[EarliestYear] [int] NULL,
	[DefaultLocation] [varchar](100) NULL,
	[DefaultGR] [varchar](6) NULL,
	[Confidential] [char](1) NULL,
	[DAFORApplies] [char](1) NULL,
 CONSTRAINT [PK_LERC_Taxon_Groups] PRIMARY KEY CLUSTERED 
(
	[Taxon_Group_Name] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
) ON [PRIMARY]
GO

/*---------------------------------------------------------------------------*\
	Populate LERC_Taxon_Groups table
\*---------------------------------------------------------------------------*/
INSERT [dbo].[LERC_Taxon_Groups] ([Taxon_Group_Name], [TaxonGroup], [DefaultCommonName], [ReportGroupName], [EarliestYear], [DefaultLocation], [DefaultGR], [Confidential], [DAFORApplies]) VALUES (N'', N'Mammals - Terrestrial (bats)', N'A Bat', N'Mammals', 0, NULL, NULL, NULL, NULL)
GO
INSERT [dbo].[LERC_Taxon_Groups] ([Taxon_Group_Name], [TaxonGroup], [DefaultCommonName], [ReportGroupName], [EarliestYear], [DefaultLocation], [DefaultGR], [Confidential], [DAFORApplies]) VALUES (N'acarine (Acari)', N'Invertebrates - Ticks & Mites', N'A Tick or Mite', N'Invertebrates', 0, NULL, NULL, NULL, NULL)
GO
INSERT [dbo].[LERC_Taxon_Groups] ([Taxon_Group_Name], [TaxonGroup], [DefaultCommonName], [ReportGroupName], [EarliestYear], [DefaultLocation], [DefaultGR], [Confidential], [DAFORApplies]) VALUES (N'acorn worm (Hemichordata)', N'Invertebrates - Acorn Worms', N'An Acorn Worm', N'Invertebrates', 0, NULL, NULL, NULL, NULL)
GO
INSERT [dbo].[LERC_Taxon_Groups] ([Taxon_Group_Name], [TaxonGroup], [DefaultCommonName], [ReportGroupName], [EarliestYear], [DefaultLocation], [DefaultGR], [Confidential], [DAFORApplies]) VALUES (N'alga', N'Lower Plants - Algae', N'An Alga', N'Plants', 0, NULL, NULL, NULL, NULL)
GO
INSERT [dbo].[LERC_Taxon_Groups] ([Taxon_Group_Name], [TaxonGroup], [DefaultCommonName], [ReportGroupName], [EarliestYear], [DefaultLocation], [DefaultGR], [Confidential], [DAFORApplies]) VALUES (N'amphibian', N'Amphibians', N'An Amphibian', N'Amphibians', 0, NULL, NULL, NULL, NULL)
GO
INSERT [dbo].[LERC_Taxon_Groups] ([Taxon_Group_Name], [TaxonGroup], [DefaultCommonName], [ReportGroupName], [EarliestYear], [DefaultLocation], [DefaultGR], [Confidential], [DAFORApplies]) VALUES (N'annelid', N'Invertebrates - Segmented Worms', N'A Segmented Worm', N'Invertebrates', 0, NULL, NULL, NULL, NULL)
GO
INSERT [dbo].[LERC_Taxon_Groups] ([Taxon_Group_Name], [TaxonGroup], [DefaultCommonName], [ReportGroupName], [EarliestYear], [DefaultLocation], [DefaultGR], [Confidential], [DAFORApplies]) VALUES (N'archaean', N'Archaea', N'An Archaean', N'Other', 0, NULL, NULL, NULL, NULL)
GO
INSERT [dbo].[LERC_Taxon_Groups] ([Taxon_Group_Name], [TaxonGroup], [DefaultCommonName], [ReportGroupName], [EarliestYear], [DefaultLocation], [DefaultGR], [Confidential], [DAFORApplies]) VALUES (N'arrow worm (Chaetognatha)', N'Invertebrates - Arrow Worms', N'An Arrow Worm', N'Invertebrates', 0, NULL, NULL, NULL, NULL)
GO
INSERT [dbo].[LERC_Taxon_Groups] ([Taxon_Group_Name], [TaxonGroup], [DefaultCommonName], [ReportGroupName], [EarliestYear], [DefaultLocation], [DefaultGR], [Confidential], [DAFORApplies]) VALUES (N'bacterium', N'Bacteria', N'A Bacterium', N'Other', 0, NULL, NULL, NULL, NULL)
GO
INSERT [dbo].[LERC_Taxon_Groups] ([Taxon_Group_Name], [TaxonGroup], [DefaultCommonName], [ReportGroupName], [EarliestYear], [DefaultLocation], [DefaultGR], [Confidential], [DAFORApplies]) VALUES (N'beardworm (Pogonophora)', N'Invertebrates - Beard Worms', N'A Beard Worm', N'Invertebrates', 0, NULL, NULL, NULL, NULL)
GO
INSERT [dbo].[LERC_Taxon_Groups] ([Taxon_Group_Name], [TaxonGroup], [DefaultCommonName], [ReportGroupName], [EarliestYear], [DefaultLocation], [DefaultGR], [Confidential], [DAFORApplies]) VALUES (N'bird', N'Birds', N'A Bird', N'Birds', 0, NULL, NULL, NULL, NULL)
GO
INSERT [dbo].[LERC_Taxon_Groups] ([Taxon_Group_Name], [TaxonGroup], [DefaultCommonName], [ReportGroupName], [EarliestYear], [DefaultLocation], [DefaultGR], [Confidential], [DAFORApplies]) VALUES (N'bony fish (Actinopterygii)', N'Fish - Bony', N'A Bony Fish', N'Fish', 0, NULL, NULL, NULL, NULL)
GO
INSERT [dbo].[LERC_Taxon_Groups] ([Taxon_Group_Name], [TaxonGroup], [DefaultCommonName], [ReportGroupName], [EarliestYear], [DefaultLocation], [DefaultGR], [Confidential], [DAFORApplies]) VALUES (N'bryozoan', N'Moss Animals', N'A Bryozoan', N'Other', 0, NULL, NULL, NULL, NULL)
GO
INSERT [dbo].[LERC_Taxon_Groups] ([Taxon_Group_Name], [TaxonGroup], [DefaultCommonName], [ReportGroupName], [EarliestYear], [DefaultLocation], [DefaultGR], [Confidential], [DAFORApplies]) VALUES (N'cartilagenous fish (Chondrichthyes)', N'Fish - Cartilagenous', N'A Cartilagenous Fish', N'Fish', 0, NULL, NULL, NULL, NULL)
GO
INSERT [dbo].[LERC_Taxon_Groups] ([Taxon_Group_Name], [TaxonGroup], [DefaultCommonName], [ReportGroupName], [EarliestYear], [DefaultLocation], [DefaultGR], [Confidential], [DAFORApplies]) VALUES (N'centipede', N'Invertebrates - Centipedes', N'A Centipede', N'Invertebrates', 0, NULL, NULL, NULL, NULL)
GO
INSERT [dbo].[LERC_Taxon_Groups] ([Taxon_Group_Name], [TaxonGroup], [DefaultCommonName], [ReportGroupName], [EarliestYear], [DefaultLocation], [DefaultGR], [Confidential], [DAFORApplies]) VALUES (N'chromist', N'Chromista', N'A Chromist', N'Other', 0, NULL, NULL, NULL, NULL)
GO
INSERT [dbo].[LERC_Taxon_Groups] ([Taxon_Group_Name], [TaxonGroup], [DefaultCommonName], [ReportGroupName], [EarliestYear], [DefaultLocation], [DefaultGR], [Confidential], [DAFORApplies]) VALUES (N'clubmoss', N'Higher Plants - Clubmosses', N'A Clubmoss', N'Plants', 0, NULL, NULL, NULL, NULL)
GO
INSERT [dbo].[LERC_Taxon_Groups] ([Taxon_Group_Name], [TaxonGroup], [DefaultCommonName], [ReportGroupName], [EarliestYear], [DefaultLocation], [DefaultGR], [Confidential], [DAFORApplies]) VALUES (N'coelenterate (=cnidarian)', N'Invertebrates - Sea Anemones, Jellyfish & Corals', N'A Sea Anemone, Jellyfish or Coral', N'Invertebrates', 0, NULL, NULL, NULL, NULL)
GO
INSERT [dbo].[LERC_Taxon_Groups] ([Taxon_Group_Name], [TaxonGroup], [DefaultCommonName], [ReportGroupName], [EarliestYear], [DefaultLocation], [DefaultGR], [Confidential], [DAFORApplies]) VALUES (N'comb jelly (Ctenophora)', N'Invertebrates - Comb Jellies', N'A Comb Jelly', N'Invertebrates', 0, NULL, NULL, NULL, NULL)
GO
INSERT [dbo].[LERC_Taxon_Groups] ([Taxon_Group_Name], [TaxonGroup], [DefaultCommonName], [ReportGroupName], [EarliestYear], [DefaultLocation], [DefaultGR], [Confidential], [DAFORApplies]) VALUES (N'conifer', N'Higher Plants - Conifers', N'A Conifer', N'Plants', 0, NULL, NULL, NULL, NULL)
GO
INSERT [dbo].[LERC_Taxon_Groups] ([Taxon_Group_Name], [TaxonGroup], [DefaultCommonName], [ReportGroupName], [EarliestYear], [DefaultLocation], [DefaultGR], [Confidential], [DAFORApplies]) VALUES (N'crustacean', N'Invertebrates - Crustaceans', N'A Crustacean', N'Invertebrates', 0, NULL, NULL, NULL, NULL)
GO
INSERT [dbo].[LERC_Taxon_Groups] ([Taxon_Group_Name], [TaxonGroup], [DefaultCommonName], [ReportGroupName], [EarliestYear], [DefaultLocation], [DefaultGR], [Confidential], [DAFORApplies]) VALUES (N'cycliophoran', N'Invertebrates - Lobster-lip parasites', N'A Cycliophoran', N'Invertebrates', 0, NULL, NULL, NULL, NULL)
GO
INSERT [dbo].[LERC_Taxon_Groups] ([Taxon_Group_Name], [TaxonGroup], [DefaultCommonName], [ReportGroupName], [EarliestYear], [DefaultLocation], [DefaultGR], [Confidential], [DAFORApplies]) VALUES (N'diatom', N'Diatoms', N'A Diatom', N'Other', 0, NULL, NULL, NULL, NULL)
GO
INSERT [dbo].[LERC_Taxon_Groups] ([Taxon_Group_Name], [TaxonGroup], [DefaultCommonName], [ReportGroupName], [EarliestYear], [DefaultLocation], [DefaultGR], [Confidential], [DAFORApplies]) VALUES (N'echinoderm', N'Invertebrates - Starfish, Sea Urchins & Sea Cucumbers', N'A Starfish, Sea Urchin or Sea Cucumber', N'Invertebrates', 0, NULL, NULL, NULL, NULL)
GO
INSERT [dbo].[LERC_Taxon_Groups] ([Taxon_Group_Name], [TaxonGroup], [DefaultCommonName], [ReportGroupName], [EarliestYear], [DefaultLocation], [DefaultGR], [Confidential], [DAFORApplies]) VALUES (N'entoproct', N'Invertebrates - Goblet Worms', N'A Goblet Worm', N'Invertebrates', 0, NULL, NULL, NULL, NULL)
GO
INSERT [dbo].[LERC_Taxon_Groups] ([Taxon_Group_Name], [TaxonGroup], [DefaultCommonName], [ReportGroupName], [EarliestYear], [DefaultLocation], [DefaultGR], [Confidential], [DAFORApplies]) VALUES (N'false scorpion (Pseudoscorpiones)', N'Invertebrates - False Scorpions', N'A False Scorpion', N'Invertebrates', 0, NULL, NULL, NULL, NULL)
GO
INSERT [dbo].[LERC_Taxon_Groups] ([Taxon_Group_Name], [TaxonGroup], [DefaultCommonName], [ReportGroupName], [EarliestYear], [DefaultLocation], [DefaultGR], [Confidential], [DAFORApplies]) VALUES (N'fern', N'Higher Plants - Ferns', N'A Fern', N'Plants', 0, NULL, NULL, NULL, NULL)
GO
INSERT [dbo].[LERC_Taxon_Groups] ([Taxon_Group_Name], [TaxonGroup], [DefaultCommonName], [ReportGroupName], [EarliestYear], [DefaultLocation], [DefaultGR], [Confidential], [DAFORApplies]) VALUES (N'flatworm (Turbellaria)', N'Invertebrates - Flatworms', N'A Flatworm', N'Invertebrates', 0, NULL, NULL, NULL, NULL)
GO
INSERT [dbo].[LERC_Taxon_Groups] ([Taxon_Group_Name], [TaxonGroup], [DefaultCommonName], [ReportGroupName], [EarliestYear], [DefaultLocation], [DefaultGR], [Confidential], [DAFORApplies]) VALUES (N'flowering plant', N'Higher Plants - Flowering Plants', N'A Flowering Plant', N'Plants', 0, NULL, NULL, NULL, NULL)
GO
INSERT [dbo].[LERC_Taxon_Groups] ([Taxon_Group_Name], [TaxonGroup], [DefaultCommonName], [ReportGroupName], [EarliestYear], [DefaultLocation], [DefaultGR], [Confidential], [DAFORApplies]) VALUES (N'foraminiferan', N'Foraminifera', N'A Foraminiferan', N'Other', 0, NULL, NULL, NULL, NULL)
GO
INSERT [dbo].[LERC_Taxon_Groups] ([Taxon_Group_Name], [TaxonGroup], [DefaultCommonName], [ReportGroupName], [EarliestYear], [DefaultLocation], [DefaultGR], [Confidential], [DAFORApplies]) VALUES (N'fungoid', N'Fungoid', N'A Fungoid', N'Fungi', 0, NULL, NULL, NULL, NULL)
GO
INSERT [dbo].[LERC_Taxon_Groups] ([Taxon_Group_Name], [TaxonGroup], [DefaultCommonName], [ReportGroupName], [EarliestYear], [DefaultLocation], [DefaultGR], [Confidential], [DAFORApplies]) VALUES (N'fungus', N'Fungi', N'A Fungus', N'Fungi', 0, NULL, NULL, NULL, NULL)
GO
INSERT [dbo].[LERC_Taxon_Groups] ([Taxon_Group_Name], [TaxonGroup], [DefaultCommonName], [ReportGroupName], [EarliestYear], [DefaultLocation], [DefaultGR], [Confidential], [DAFORApplies]) VALUES (N'gastrotrich', N'Invertebrates - Hairybacks', N'A Hairyback Invertebrate', N'Invertebrates', 0, NULL, NULL, NULL, NULL)
GO
INSERT [dbo].[LERC_Taxon_Groups] ([Taxon_Group_Name], [TaxonGroup], [DefaultCommonName], [ReportGroupName], [EarliestYear], [DefaultLocation], [DefaultGR], [Confidential], [DAFORApplies]) VALUES (N'ginkgo', N'Lower Plants - Ginkgo', N'A Ginkgo', N'Plants', 0, NULL, NULL, NULL, NULL)
GO
INSERT [dbo].[LERC_Taxon_Groups] ([Taxon_Group_Name], [TaxonGroup], [DefaultCommonName], [ReportGroupName], [EarliestYear], [DefaultLocation], [DefaultGR], [Confidential], [DAFORApplies]) VALUES (N'gnathostomulid', N'Invertebrates - Jaw Worms', N'A Jaw Worm', N'Invertebrates', 0, NULL, NULL, NULL, NULL)
GO
INSERT [dbo].[LERC_Taxon_Groups] ([Taxon_Group_Name], [TaxonGroup], [DefaultCommonName], [ReportGroupName], [EarliestYear], [DefaultLocation], [DefaultGR], [Confidential], [DAFORApplies]) VALUES (N'hairworm (Nematomorpha)', N'Invertebrates - Horsehair Worms', N'A Horsehair Worm', N'Invertebrates', 0, NULL, NULL, NULL, NULL)
GO
INSERT [dbo].[LERC_Taxon_Groups] ([Taxon_Group_Name], [TaxonGroup], [DefaultCommonName], [ReportGroupName], [EarliestYear], [DefaultLocation], [DefaultGR], [Confidential], [DAFORApplies]) VALUES (N'harvestman (Opiliones)', N'Invertebrates - Harvestmen', N'A Harvestman', N'Invertebrates', 0, NULL, NULL, NULL, NULL)
GO
INSERT [dbo].[LERC_Taxon_Groups] ([Taxon_Group_Name], [TaxonGroup], [DefaultCommonName], [ReportGroupName], [EarliestYear], [DefaultLocation], [DefaultGR], [Confidential], [DAFORApplies]) VALUES (N'hornwort', N'Lower Plants - Hornworts', N'A Hornwort', N'Plants', 0, NULL, NULL, NULL, NULL)
GO
INSERT [dbo].[LERC_Taxon_Groups] ([Taxon_Group_Name], [TaxonGroup], [DefaultCommonName], [ReportGroupName], [EarliestYear], [DefaultLocation], [DefaultGR], [Confidential], [DAFORApplies]) VALUES (N'horseshoe worm (Phoronida)', N'Invertebrates - Horseshoe Worms', N'A Horseshoe Worm', N'Invertebrates', 0, NULL, NULL, NULL, NULL)
GO
INSERT [dbo].[LERC_Taxon_Groups] ([Taxon_Group_Name], [TaxonGroup], [DefaultCommonName], [ReportGroupName], [EarliestYear], [DefaultLocation], [DefaultGR], [Confidential], [DAFORApplies]) VALUES (N'horsetail', N'Higher Plants - Horsetails', N'A Horsetail', N'Plants', 0, NULL, NULL, NULL, NULL)
GO
INSERT [dbo].[LERC_Taxon_Groups] ([Taxon_Group_Name], [TaxonGroup], [DefaultCommonName], [ReportGroupName], [EarliestYear], [DefaultLocation], [DefaultGR], [Confidential], [DAFORApplies]) VALUES (N'insect - alderfly (Megaloptera)', N'Invertebrates - Alderflies', N'An Alderfly', N'Invertebrates', 0, NULL, NULL, NULL, NULL)
GO
INSERT [dbo].[LERC_Taxon_Groups] ([Taxon_Group_Name], [TaxonGroup], [DefaultCommonName], [ReportGroupName], [EarliestYear], [DefaultLocation], [DefaultGR], [Confidential], [DAFORApplies]) VALUES (N'insect - beetle (Coleoptera)', N'Invertebrates - Beetles', N'A Beetle', N'Invertebrates', 0, NULL, NULL, NULL, NULL)
GO
INSERT [dbo].[LERC_Taxon_Groups] ([Taxon_Group_Name], [TaxonGroup], [DefaultCommonName], [ReportGroupName], [EarliestYear], [DefaultLocation], [DefaultGR], [Confidential], [DAFORApplies]) VALUES (N'insect - booklouse (Psocoptera)', N'Invertebrates - Booklice', N'A Booklouse', N'Invertebrates', 0, NULL, NULL, NULL, NULL)
GO
INSERT [dbo].[LERC_Taxon_Groups] ([Taxon_Group_Name], [TaxonGroup], [DefaultCommonName], [ReportGroupName], [EarliestYear], [DefaultLocation], [DefaultGR], [Confidential], [DAFORApplies]) VALUES (N'insect - bristletail (Archaeognatha)', N'Invertebrates - Jumping Bristletails', N'A Jumping Bristletail', N'Invertebrates', 0, NULL, NULL, NULL, NULL)
GO
INSERT [dbo].[LERC_Taxon_Groups] ([Taxon_Group_Name], [TaxonGroup], [DefaultCommonName], [ReportGroupName], [EarliestYear], [DefaultLocation], [DefaultGR], [Confidential], [DAFORApplies]) VALUES (N'insect - butterfly', N'Invertebrates - Butterflies', N'A Butterfly', N'Invertebrates', 0, NULL, NULL, NULL, NULL)
GO
INSERT [dbo].[LERC_Taxon_Groups] ([Taxon_Group_Name], [TaxonGroup], [DefaultCommonName], [ReportGroupName], [EarliestYear], [DefaultLocation], [DefaultGR], [Confidential], [DAFORApplies]) VALUES (N'insect - caddis fly (Trichoptera)', N'Invertebrates - Caddis Flies', N'A Caddis Fly', N'Invertebrates', 0, NULL, NULL, NULL, NULL)
GO
INSERT [dbo].[LERC_Taxon_Groups] ([Taxon_Group_Name], [TaxonGroup], [DefaultCommonName], [ReportGroupName], [EarliestYear], [DefaultLocation], [DefaultGR], [Confidential], [DAFORApplies]) VALUES (N'insect - cockroach (Dictyoptera)', N'Invertebrates - Cockroaches', N'A Cockroach', N'Invertebrates', 0, NULL, NULL, NULL, NULL)
GO
INSERT [dbo].[LERC_Taxon_Groups] ([Taxon_Group_Name], [TaxonGroup], [DefaultCommonName], [ReportGroupName], [EarliestYear], [DefaultLocation], [DefaultGR], [Confidential], [DAFORApplies]) VALUES (N'insect - dragonfly (Odonata)', N'Invertebrates - Dragonflies & Damselflies', N'A Dragonfly or Damselfly', N'Invertebrates', 0, NULL, NULL, NULL, NULL)
GO
INSERT [dbo].[LERC_Taxon_Groups] ([Taxon_Group_Name], [TaxonGroup], [DefaultCommonName], [ReportGroupName], [EarliestYear], [DefaultLocation], [DefaultGR], [Confidential], [DAFORApplies]) VALUES (N'insect - earwig (Dermaptera)', N'Invertebrates - Earwigs', N'An Earwig', N'Invertebrates', 0, NULL, NULL, NULL, NULL)
GO
INSERT [dbo].[LERC_Taxon_Groups] ([Taxon_Group_Name], [TaxonGroup], [DefaultCommonName], [ReportGroupName], [EarliestYear], [DefaultLocation], [DefaultGR], [Confidential], [DAFORApplies]) VALUES (N'insect - flea (Siphonaptera)', N'Invertebrates - Fleas', N'A Flea', N'Invertebrates', 0, NULL, NULL, NULL, NULL)
GO
INSERT [dbo].[LERC_Taxon_Groups] ([Taxon_Group_Name], [TaxonGroup], [DefaultCommonName], [ReportGroupName], [EarliestYear], [DefaultLocation], [DefaultGR], [Confidential], [DAFORApplies]) VALUES (N'insect - hymenopteran', N'Invertebrates - Ants, Bees, Sawflies & Wasps', N'An Ant, Bee, Sawfly or Wasp', N'Invertebrates', 0, NULL, NULL, NULL, NULL)
GO
INSERT [dbo].[LERC_Taxon_Groups] ([Taxon_Group_Name], [TaxonGroup], [DefaultCommonName], [ReportGroupName], [EarliestYear], [DefaultLocation], [DefaultGR], [Confidential], [DAFORApplies]) VALUES (N'insect - lacewing (Neuroptera)', N'Invertebrates - Lacewings', N'A Lacewing', N'Invertebrates', 0, NULL, NULL, NULL, NULL)
GO
INSERT [dbo].[LERC_Taxon_Groups] ([Taxon_Group_Name], [TaxonGroup], [DefaultCommonName], [ReportGroupName], [EarliestYear], [DefaultLocation], [DefaultGR], [Confidential], [DAFORApplies]) VALUES (N'insect - louse (Phthiraptera)', N'Invertebrates - Lice', N'A Louse', N'Invertebrates', 0, NULL, NULL, NULL, NULL)
GO
INSERT [dbo].[LERC_Taxon_Groups] ([Taxon_Group_Name], [TaxonGroup], [DefaultCommonName], [ReportGroupName], [EarliestYear], [DefaultLocation], [DefaultGR], [Confidential], [DAFORApplies]) VALUES (N'insect - mantis (Mantodea)', N'Invertebrates - Praying Mantises', N'A Praying Mantis', N'Invertebrates', 0, NULL, NULL, NULL, NULL)
GO
INSERT [dbo].[LERC_Taxon_Groups] ([Taxon_Group_Name], [TaxonGroup], [DefaultCommonName], [ReportGroupName], [EarliestYear], [DefaultLocation], [DefaultGR], [Confidential], [DAFORApplies]) VALUES (N'insect - mayfly (Ephemeroptera)', N'Invertebrates - Mayflies', N'A Mayfly', N'Invertebrates', 0, NULL, NULL, NULL, NULL)
GO
INSERT [dbo].[LERC_Taxon_Groups] ([Taxon_Group_Name], [TaxonGroup], [DefaultCommonName], [ReportGroupName], [EarliestYear], [DefaultLocation], [DefaultGR], [Confidential], [DAFORApplies]) VALUES (N'insect - moth', N'Invertebrates - Moths', N'A Moth', N'Invertebrates', 0, NULL, NULL, NULL, NULL)
GO
INSERT [dbo].[LERC_Taxon_Groups] ([Taxon_Group_Name], [TaxonGroup], [DefaultCommonName], [ReportGroupName], [EarliestYear], [DefaultLocation], [DefaultGR], [Confidential], [DAFORApplies]) VALUES (N'insect - orthopteran', N'Invertebrates - Grasshoppers & Crickets', N'A Grasshopper or Cricket', N'Invertebrates', 0, NULL, NULL, NULL, NULL)
GO
INSERT [dbo].[LERC_Taxon_Groups] ([Taxon_Group_Name], [TaxonGroup], [DefaultCommonName], [ReportGroupName], [EarliestYear], [DefaultLocation], [DefaultGR], [Confidential], [DAFORApplies]) VALUES (N'insect - scorpion fly (Mecoptera)', N'Invertebrates - Scorpionflies', N'A Scorpionfly', N'Invertebrates', 0, NULL, NULL, NULL, NULL)
GO
INSERT [dbo].[LERC_Taxon_Groups] ([Taxon_Group_Name], [TaxonGroup], [DefaultCommonName], [ReportGroupName], [EarliestYear], [DefaultLocation], [DefaultGR], [Confidential], [DAFORApplies]) VALUES (N'insect - silverfish (Thysanura)', N'Invertebrates - Silverfish', N'A Silverfish', N'Invertebrates', 0, NULL, NULL, NULL, NULL)
GO
INSERT [dbo].[LERC_Taxon_Groups] ([Taxon_Group_Name], [TaxonGroup], [DefaultCommonName], [ReportGroupName], [EarliestYear], [DefaultLocation], [DefaultGR], [Confidential], [DAFORApplies]) VALUES (N'insect - snakefly (Raphidioptera)', N'Invertebrates - Snakeflies', N'A Snakefly', N'Invertebrates', 0, NULL, NULL, NULL, NULL)
GO
INSERT [dbo].[LERC_Taxon_Groups] ([Taxon_Group_Name], [TaxonGroup], [DefaultCommonName], [ReportGroupName], [EarliestYear], [DefaultLocation], [DefaultGR], [Confidential], [DAFORApplies]) VALUES (N'insect - stick insect (Phasmida)', N'Invertebrates - Stick & Leaf Insects', N'A Stick or Leaf Insect', N'Invertebrates', 0, NULL, NULL, NULL, NULL)
GO
INSERT [dbo].[LERC_Taxon_Groups] ([Taxon_Group_Name], [TaxonGroup], [DefaultCommonName], [ReportGroupName], [EarliestYear], [DefaultLocation], [DefaultGR], [Confidential], [DAFORApplies]) VALUES (N'insect - stonefly (Plecoptera)', N'Invertebrates - Stoneflies', N'A Stonefly', N'Invertebrates', 0, NULL, NULL, NULL, NULL)
GO
INSERT [dbo].[LERC_Taxon_Groups] ([Taxon_Group_Name], [TaxonGroup], [DefaultCommonName], [ReportGroupName], [EarliestYear], [DefaultLocation], [DefaultGR], [Confidential], [DAFORApplies]) VALUES (N'insect - stylops (Strepsiptera)', N'Invertebrates - Twisted-wing Insects', N'A Twisted-wing Insect', N'Invertebrates', 0, NULL, NULL, NULL, NULL)
GO
INSERT [dbo].[LERC_Taxon_Groups] ([Taxon_Group_Name], [TaxonGroup], [DefaultCommonName], [ReportGroupName], [EarliestYear], [DefaultLocation], [DefaultGR], [Confidential], [DAFORApplies]) VALUES (N'insect - thrips (Thysanoptera)', N'Invertebrates - Thrips', N'A Thrip', N'Invertebrates', 0, NULL, NULL, NULL, NULL)
GO
INSERT [dbo].[LERC_Taxon_Groups] ([Taxon_Group_Name], [TaxonGroup], [DefaultCommonName], [ReportGroupName], [EarliestYear], [DefaultLocation], [DefaultGR], [Confidential], [DAFORApplies]) VALUES (N'insect - true bug (Hemiptera)', N'Invertebrates - True Bugs', N'A True Bug', N'Invertebrates', 0, NULL, NULL, NULL, NULL)
GO
INSERT [dbo].[LERC_Taxon_Groups] ([Taxon_Group_Name], [TaxonGroup], [DefaultCommonName], [ReportGroupName], [EarliestYear], [DefaultLocation], [DefaultGR], [Confidential], [DAFORApplies]) VALUES (N'insect - true fly (Diptera)', N'Invertebrates - True Flies', N'A True Fly', N'Invertebrates', 0, NULL, NULL, NULL, NULL)
GO
INSERT [dbo].[LERC_Taxon_Groups] ([Taxon_Group_Name], [TaxonGroup], [DefaultCommonName], [ReportGroupName], [EarliestYear], [DefaultLocation], [DefaultGR], [Confidential], [DAFORApplies]) VALUES (N'jawless fish (Agnatha)', N'Fish - Jawless', N'A Jawless Fish', N'Fish', 0, NULL, NULL, NULL, NULL)
GO
INSERT [dbo].[LERC_Taxon_Groups] ([Taxon_Group_Name], [TaxonGroup], [DefaultCommonName], [ReportGroupName], [EarliestYear], [DefaultLocation], [DefaultGR], [Confidential], [DAFORApplies]) VALUES (N'lampshell (Brachiopoda)', N'Invertebrates - Lampshells', N'A Lampshell', N'Invertebrates', 0, NULL, NULL, NULL, NULL)
GO
INSERT [dbo].[LERC_Taxon_Groups] ([Taxon_Group_Name], [TaxonGroup], [DefaultCommonName], [ReportGroupName], [EarliestYear], [DefaultLocation], [DefaultGR], [Confidential], [DAFORApplies]) VALUES (N'lancelet (Cephalochordata)', N'Invertebrates - Lancelets', N'A Lancelet', N'Invertebrates', 0, NULL, NULL, NULL, NULL)
GO
INSERT [dbo].[LERC_Taxon_Groups] ([Taxon_Group_Name], [TaxonGroup], [DefaultCommonName], [ReportGroupName], [EarliestYear], [DefaultLocation], [DefaultGR], [Confidential], [DAFORApplies]) VALUES (N'lichen', N'Lichens', N'A Lichen', N'Plants', 0, NULL, NULL, NULL, NULL)
GO
INSERT [dbo].[LERC_Taxon_Groups] ([Taxon_Group_Name], [TaxonGroup], [DefaultCommonName], [ReportGroupName], [EarliestYear], [DefaultLocation], [DefaultGR], [Confidential], [DAFORApplies]) VALUES (N'liverwort', N'Lower Plants - Liverworts', N'A Liverwort', N'Plants', 0, NULL, NULL, NULL, NULL)
GO
INSERT [dbo].[LERC_Taxon_Groups] ([Taxon_Group_Name], [TaxonGroup], [DefaultCommonName], [ReportGroupName], [EarliestYear], [DefaultLocation], [DefaultGR], [Confidential], [DAFORApplies]) VALUES (N'loriciferan', N'Loricifera', N'A Loriciferan', N'Other', 0, NULL, NULL, NULL, NULL)
GO
INSERT [dbo].[LERC_Taxon_Groups] ([Taxon_Group_Name], [TaxonGroup], [DefaultCommonName], [ReportGroupName], [EarliestYear], [DefaultLocation], [DefaultGR], [Confidential], [DAFORApplies]) VALUES (N'marine mammal', N'Mammals - Marine', N'A Marine Mammal', N'Mammals', 0, NULL, NULL, NULL, NULL)
GO
INSERT [dbo].[LERC_Taxon_Groups] ([Taxon_Group_Name], [TaxonGroup], [DefaultCommonName], [ReportGroupName], [EarliestYear], [DefaultLocation], [DefaultGR], [Confidential], [DAFORApplies]) VALUES (N'mesozoan', N'Mesozoa', N'A Mesozoan', N'Other', 0, NULL, NULL, NULL, NULL)
GO
INSERT [dbo].[LERC_Taxon_Groups] ([Taxon_Group_Name], [TaxonGroup], [DefaultCommonName], [ReportGroupName], [EarliestYear], [DefaultLocation], [DefaultGR], [Confidential], [DAFORApplies]) VALUES (N'millipede', N'Invertebrates - Millipedes', N'A Millipede', N'Invertebrates', 0, NULL, NULL, NULL, NULL)
GO
INSERT [dbo].[LERC_Taxon_Groups] ([Taxon_Group_Name], [TaxonGroup], [DefaultCommonName], [ReportGroupName], [EarliestYear], [DefaultLocation], [DefaultGR], [Confidential], [DAFORApplies]) VALUES (N'mollusc', N'Invertebrates - Molluscs', N'A Mollusc', N'Invertebrates', 0, NULL, NULL, NULL, NULL)
GO
INSERT [dbo].[LERC_Taxon_Groups] ([Taxon_Group_Name], [TaxonGroup], [DefaultCommonName], [ReportGroupName], [EarliestYear], [DefaultLocation], [DefaultGR], [Confidential], [DAFORApplies]) VALUES (N'monogenean', N'Parasitic Flatworms', N'A Parasitic Flatworm', N'Invertebrates', 0, NULL, NULL, NULL, NULL)
GO
INSERT [dbo].[LERC_Taxon_Groups] ([Taxon_Group_Name], [TaxonGroup], [DefaultCommonName], [ReportGroupName], [EarliestYear], [DefaultLocation], [DefaultGR], [Confidential], [DAFORApplies]) VALUES (N'moss', N'Lower Plants - Mosses', N'A Moss', N'Plants', 0, NULL, NULL, NULL, NULL)
GO
INSERT [dbo].[LERC_Taxon_Groups] ([Taxon_Group_Name], [TaxonGroup], [DefaultCommonName], [ReportGroupName], [EarliestYear], [DefaultLocation], [DefaultGR], [Confidential], [DAFORApplies]) VALUES (N'mud dragon (Kinorhyncha)', N'Invertebrates - Mud Dragons', N'A Mud Dragon', N'Invertebrates', 0, NULL, NULL, NULL, NULL)
GO
INSERT [dbo].[LERC_Taxon_Groups] ([Taxon_Group_Name], [TaxonGroup], [DefaultCommonName], [ReportGroupName], [EarliestYear], [DefaultLocation], [DefaultGR], [Confidential], [DAFORApplies]) VALUES (N'parasitic roundworm (Nematoda)', N'Invertebrates - Parasitic Roundworms', N'A Parasitic Roundworm', N'Invertebrates', 0, NULL, NULL, NULL, NULL)
GO
INSERT [dbo].[LERC_Taxon_Groups] ([Taxon_Group_Name], [TaxonGroup], [DefaultCommonName], [ReportGroupName], [EarliestYear], [DefaultLocation], [DefaultGR], [Confidential], [DAFORApplies]) VALUES (N'pauropod', N'Pauropoda', N'A Pauropod', N'Other', 0, NULL, NULL, NULL, NULL)
GO
INSERT [dbo].[LERC_Taxon_Groups] ([Taxon_Group_Name], [TaxonGroup], [DefaultCommonName], [ReportGroupName], [EarliestYear], [DefaultLocation], [DefaultGR], [Confidential], [DAFORApplies]) VALUES (N'peanut worm (Sipuncula)', N'Invertebrates - Peanut Worms', N'A Peanut Worm', N'Invertebrates', 0, NULL, NULL, NULL, NULL)
GO
INSERT [dbo].[LERC_Taxon_Groups] ([Taxon_Group_Name], [TaxonGroup], [DefaultCommonName], [ReportGroupName], [EarliestYear], [DefaultLocation], [DefaultGR], [Confidential], [DAFORApplies]) VALUES (N'placozoan', N'Placozoa', N'A Placozoan', N'Other', 0, NULL, NULL, NULL, NULL)
GO
INSERT [dbo].[LERC_Taxon_Groups] ([Taxon_Group_Name], [TaxonGroup], [DefaultCommonName], [ReportGroupName], [EarliestYear], [DefaultLocation], [DefaultGR], [Confidential], [DAFORApplies]) VALUES (N'priapulid', N'Priapulids', N'A Priapulid', N'Other', 0, NULL, NULL, NULL, NULL)
GO
INSERT [dbo].[LERC_Taxon_Groups] ([Taxon_Group_Name], [TaxonGroup], [DefaultCommonName], [ReportGroupName], [EarliestYear], [DefaultLocation], [DefaultGR], [Confidential], [DAFORApplies]) VALUES (N'protozoan', N'Protozoa', N'A Protozoan', N'Other', 0, NULL, NULL, NULL, NULL)
GO
INSERT [dbo].[LERC_Taxon_Groups] ([Taxon_Group_Name], [TaxonGroup], [DefaultCommonName], [ReportGroupName], [EarliestYear], [DefaultLocation], [DefaultGR], [Confidential], [DAFORApplies]) VALUES (N'proturan', N'Protura', N'A Proturan', N'Other', 0, NULL, NULL, NULL, NULL)
GO
INSERT [dbo].[LERC_Taxon_Groups] ([Taxon_Group_Name], [TaxonGroup], [DefaultCommonName], [ReportGroupName], [EarliestYear], [DefaultLocation], [DefaultGR], [Confidential], [DAFORApplies]) VALUES (N'quillwort', N'Higher Plants - Quillworts', N'A Quillwort', N'Plants', 0, NULL, NULL, NULL, NULL)
GO
INSERT [dbo].[LERC_Taxon_Groups] ([Taxon_Group_Name], [TaxonGroup], [DefaultCommonName], [ReportGroupName], [EarliestYear], [DefaultLocation], [DefaultGR], [Confidential], [DAFORApplies]) VALUES (N'reptile', N'Reptiles', N'A Reptile', N'Reptiles', 0, NULL, NULL, NULL, NULL)
GO
INSERT [dbo].[LERC_Taxon_Groups] ([Taxon_Group_Name], [TaxonGroup], [DefaultCommonName], [ReportGroupName], [EarliestYear], [DefaultLocation], [DefaultGR], [Confidential], [DAFORApplies]) VALUES (N'ribbon worm (Nemertinea)', N'Invertebrates - Ribbon worms', N'A Ribbon worm', N'Invertebrates', 0, NULL, NULL, NULL, NULL)
GO
INSERT [dbo].[LERC_Taxon_Groups] ([Taxon_Group_Name], [TaxonGroup], [DefaultCommonName], [ReportGroupName], [EarliestYear], [DefaultLocation], [DefaultGR], [Confidential], [DAFORApplies]) VALUES (N'rotifer', N'Invertebrates - Rotifers', N'A Rotifer', N'Invertebrates', 0, NULL, NULL, NULL, NULL)
GO
INSERT [dbo].[LERC_Taxon_Groups] ([Taxon_Group_Name], [TaxonGroup], [DefaultCommonName], [ReportGroupName], [EarliestYear], [DefaultLocation], [DefaultGR], [Confidential], [DAFORApplies]) VALUES (N'roundworm (Nematoda)', N'Invertebrates - Roundworms', N'A Roundworm', N'Invertebrates', 0, NULL, NULL, NULL, NULL)
GO
INSERT [dbo].[LERC_Taxon_Groups] ([Taxon_Group_Name], [TaxonGroup], [DefaultCommonName], [ReportGroupName], [EarliestYear], [DefaultLocation], [DefaultGR], [Confidential], [DAFORApplies]) VALUES (N'scorpion', N'Scorpions', N'A Scorpion', N'Invertebrates', 0, NULL, NULL, NULL, NULL)
GO
INSERT [dbo].[LERC_Taxon_Groups] ([Taxon_Group_Name], [TaxonGroup], [DefaultCommonName], [ReportGroupName], [EarliestYear], [DefaultLocation], [DefaultGR], [Confidential], [DAFORApplies]) VALUES (N'sea spider (Pycnogonida)', N'Invertebrates - Sea Spiders', N'A Sea Spider', N'Invertebrates', 0, NULL, NULL, NULL, NULL)
GO
INSERT [dbo].[LERC_Taxon_Groups] ([Taxon_Group_Name], [TaxonGroup], [DefaultCommonName], [ReportGroupName], [EarliestYear], [DefaultLocation], [DefaultGR], [Confidential], [DAFORApplies]) VALUES (N'slime mould', N'Slime Moulds', N'A Slime Mould', N'Other', 0, NULL, NULL, NULL, NULL)
GO
INSERT [dbo].[LERC_Taxon_Groups] ([Taxon_Group_Name], [TaxonGroup], [DefaultCommonName], [ReportGroupName], [EarliestYear], [DefaultLocation], [DefaultGR], [Confidential], [DAFORApplies]) VALUES (N'spider (Araneae)', N'Invertebrates - Spiders', N'A Spider', N'Invertebrates', 0, NULL, NULL, NULL, NULL)
GO
INSERT [dbo].[LERC_Taxon_Groups] ([Taxon_Group_Name], [TaxonGroup], [DefaultCommonName], [ReportGroupName], [EarliestYear], [DefaultLocation], [DefaultGR], [Confidential], [DAFORApplies]) VALUES (N'sponge (Porifera)', N'Invertebrates - Sponges', N'A Sponge', N'Invertebrates', 0, NULL, NULL, NULL, NULL)
GO
INSERT [dbo].[LERC_Taxon_Groups] ([Taxon_Group_Name], [TaxonGroup], [DefaultCommonName], [ReportGroupName], [EarliestYear], [DefaultLocation], [DefaultGR], [Confidential], [DAFORApplies]) VALUES (N'spoon worm (Echiura)', N'Invertebrates - Spoon Worms', N'A Spoon Worm', N'Invertebrates', 0, NULL, NULL, NULL, NULL)
GO
INSERT [dbo].[LERC_Taxon_Groups] ([Taxon_Group_Name], [TaxonGroup], [DefaultCommonName], [ReportGroupName], [EarliestYear], [DefaultLocation], [DefaultGR], [Confidential], [DAFORApplies]) VALUES (N'springtail (Collembola)', N'Invertebrates - Springtails', N'A Springtail', N'Invertebrates', 0, NULL, NULL, NULL, NULL)
GO
INSERT [dbo].[LERC_Taxon_Groups] ([Taxon_Group_Name], [TaxonGroup], [DefaultCommonName], [ReportGroupName], [EarliestYear], [DefaultLocation], [DefaultGR], [Confidential], [DAFORApplies]) VALUES (N'stonewort', N'Lower Plants - Stoneworts', N'A Stonewort', N'Plants', 0, NULL, NULL, NULL, NULL)
GO
INSERT [dbo].[LERC_Taxon_Groups] ([Taxon_Group_Name], [TaxonGroup], [DefaultCommonName], [ReportGroupName], [EarliestYear], [DefaultLocation], [DefaultGR], [Confidential], [DAFORApplies]) VALUES (N'symphylan', N'Invertebrates - Garden Centipedes', N'A Garden Centipede', N'Invertebrates', 0, NULL, NULL, NULL, NULL)
GO
INSERT [dbo].[LERC_Taxon_Groups] ([Taxon_Group_Name], [TaxonGroup], [DefaultCommonName], [ReportGroupName], [EarliestYear], [DefaultLocation], [DefaultGR], [Confidential], [DAFORApplies]) VALUES (N'tapeworm (Cestoda)', N'Invertebrates - Tapeworms', N'A Tapeworm', N'Invertebrates', 0, NULL, NULL, NULL, NULL)
GO
INSERT [dbo].[LERC_Taxon_Groups] ([Taxon_Group_Name], [TaxonGroup], [DefaultCommonName], [ReportGroupName], [EarliestYear], [DefaultLocation], [DefaultGR], [Confidential], [DAFORApplies]) VALUES (N'terrestrial mammal', N'Mammals - Terrestrial (excl. bats)', N'A Terrestrial Mammal (excl. bats)', N'Mammals', 0, NULL, NULL, NULL, NULL)
GO
INSERT [dbo].[LERC_Taxon_Groups] ([Taxon_Group_Name], [TaxonGroup], [DefaultCommonName], [ReportGroupName], [EarliestYear], [DefaultLocation], [DefaultGR], [Confidential], [DAFORApplies]) VALUES (N'thorny-headed worm (Acanthocephala)', N'Invertebrates - Thorny-headed Worms', N'A Thorny-headed Worm', N'Invertebrates', 0, NULL, NULL, NULL, NULL)
GO
INSERT [dbo].[LERC_Taxon_Groups] ([Taxon_Group_Name], [TaxonGroup], [DefaultCommonName], [ReportGroupName], [EarliestYear], [DefaultLocation], [DefaultGR], [Confidential], [DAFORApplies]) VALUES (N'tongue worm (Pentastomida)', N'Invertebrates - Tongue Worms', N'A Tongue Worm', N'Invertebrates', 0, NULL, NULL, NULL, NULL)
GO
INSERT [dbo].[LERC_Taxon_Groups] ([Taxon_Group_Name], [TaxonGroup], [DefaultCommonName], [ReportGroupName], [EarliestYear], [DefaultLocation], [DefaultGR], [Confidential], [DAFORApplies]) VALUES (N'trematode', N'Invertebrates - Flukes', N'A Fluke', N'Invertebrates', 0, NULL, NULL, NULL, NULL)
GO
INSERT [dbo].[LERC_Taxon_Groups] ([Taxon_Group_Name], [TaxonGroup], [DefaultCommonName], [ReportGroupName], [EarliestYear], [DefaultLocation], [DefaultGR], [Confidential], [DAFORApplies]) VALUES (N'tunicate (Urochordata)', N'Invertebrates - Sea Squirts', N'A Sea Squirt', N'Invertebrates', 0, NULL, NULL, NULL, NULL)
GO
INSERT [dbo].[LERC_Taxon_Groups] ([Taxon_Group_Name], [TaxonGroup], [DefaultCommonName], [ReportGroupName], [EarliestYear], [DefaultLocation], [DefaultGR], [Confidential], [DAFORApplies]) VALUES (N'two-tailed bristletail (Diplura)', N'Invertebrates - Two-pronged Bristletails', N'A Two-pronged Bristletail', N'Invertebrates', 0, NULL, NULL, NULL, NULL)
GO
INSERT [dbo].[LERC_Taxon_Groups] ([Taxon_Group_Name], [TaxonGroup], [DefaultCommonName], [ReportGroupName], [EarliestYear], [DefaultLocation], [DefaultGR], [Confidential], [DAFORApplies]) VALUES (N'unassigned', N'Unassigned', N'Unassigned', N'Other', 0, NULL, NULL, NULL, NULL)
GO
INSERT [dbo].[LERC_Taxon_Groups] ([Taxon_Group_Name], [TaxonGroup], [DefaultCommonName], [ReportGroupName], [EarliestYear], [DefaultLocation], [DefaultGR], [Confidential], [DAFORApplies]) VALUES (N'undetermined', N'Undetermined', N'Undetermined', N'Other', 0, NULL, NULL, NULL, NULL)
GO
INSERT [dbo].[LERC_Taxon_Groups] ([Taxon_Group_Name], [TaxonGroup], [DefaultCommonName], [ReportGroupName], [EarliestYear], [DefaultLocation], [DefaultGR], [Confidential], [DAFORApplies]) VALUES (N'virus', N'Viruses', N'A Virus', N'Other', 0, NULL, NULL, NULL, NULL)
GO
INSERT [dbo].[LERC_Taxon_Groups] ([Taxon_Group_Name], [TaxonGroup], [DefaultCommonName], [ReportGroupName], [EarliestYear], [DefaultLocation], [DefaultGR], [Confidential], [DAFORApplies]) VALUES (N'waterbear (Tardigrada)', N'Invertebrates - Water-bears', N'A Water-bear', N'Invertebrates', 0, NULL, NULL, NULL, NULL)
GO
